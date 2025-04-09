require 'active_merchant'
require 'sdn/db'

# SDN Credit Card Library
#
# Author: Jimmy Gleason <jimmy@sdninc.co>
# 
# The purpose of this class is to encapsulate any functionality related to a credit card.
# This includes, loading a user's card from the DB, creating a new card, charging a card
# against the payment gateway, and verifying a credit card's details.
#
# NOTE: Methods with a bang (!) will make an API request to the gateway.
#
# Usage:
#   Create a new card for a user:
#     Card.new(current_user).from_new_details(first_name: 'Monty', ... ).to_model.save
#   Create a new card and serialize it for storage in session/cart/etc:
#     Card.new(current_user).from_new_details(name: 'Biggus Dickus', ... ).to_json
#   Unserializes card and then charges it and then saves it to the DB:
#     Card.new(current_user).from_json(...).charge!(...).to_model.save
#   Load a card belonging to a user:
#     Card.new(current_user).from_model(CreditCard.get(23))
#   Charge a loaded card:
#     Card.new(current_user).from_json(...).charge!(...)
#
# TODO: Consolidate card output (see charge method's response)

class SDN::Card

    # TODO: Add tests for user_message
    # TODO: Abstract exceptions to global exceptions w/ user message
    module Exceptions
        class Error < RuntimeError  
            attr_reader :user_message
            def initialize(message, user_message:nil)
                super(message)
                @user_message = user_message == :message ? message : (user_message || 'Unknown error.')
            end
        end
        class DetailsError        < Error;         end
        class MissingDetails      < DetailsError;  end
        class InvalidDetails      < DetailsError;  end
        class GatewayError        < Error;         end
        class GatewayRejection    < GatewayError;  end
        class GatewayThrottled    < GatewayError;  end
        class NotChargeable       < Error;         end
        class DatabaseError       < Error;         end
        class InvalidModel        < DatabaseError; end
        class InvalidJson         < Error;         end
        class InvalidHash         < Error;         end
    end
    include Exceptions

    attr_reader :token, :last_pn_ref, :card_type, :last_four, :exp_month, :exp_year, :model,
                :first_name, :last_name, :address1, :city, :state, :zip

    const_def :CONFIG_FILE, "config/payleap.yml"

    const_def :REQUIRED_DETAILS, [ :first_name, :last_name, :number, :verification, :exp_month, 
                                   :exp_year, :address1, :city, :state, :zip ]

    const_def :CENSORED_FIELDS,      [ :number, :verification ]
    const_def :CENSORED_REPLACEMENT, '[NOT SHOWN]'

    const_def :PAYLEAP_ERROR_CODES, { '208' => 'Card expired', '207' => 'Card declined', '210' => 'Card rejected', 'unknown' => 'Unknown card error', }

    const_def :THROTTLE_NUM, 10 # number of requests per...
    const_def :THROTTLE_TIME, 30 # time in seconds

    
    # Initializes payment gateway
    #
    # user_id is to provide an (optional) context when interacting with the DB. This is
    # used for things like logging payment gateway requests, interacting with user's
    # cards, etc.
    def initialize(user, dry_run: false)
        @user = user.is_a?(User) ? user : User.get(user.to_i)
        @dry_run = dry_run

        if dry_run || !Rails.env.production?
            $LOG.info "Payment Gateway mode: TEST"
            ActiveMerchant::Billing::Base.mode = :test
        else
            $LOG.info "Payment Gateway mode: PRODUCTION - real transactions are happening"            
        end

        config = ::SDN::Config.load(SDNROOT / CONFIG_FILE)
        @payment_gateway = ActiveMerchant::Billing::PayleapGateway.new(
            login: config[:login],
            password: config[:password],
        )
    end

    # Accepts fresh card details and creates token from gateway
    # 
    # Accepted details:
    #  first_name    (req)
    #  last_name     (req)
    #  name                 Converted to first/last
    #  number        (req)  CC number - must be 16 digits
    #  verification  (req)  Must be less than 5 digits
    #  exp_month     (req)  Must be 1 or 2 digits
    #  exp_year      (req)  Must be 4 digits
    #  address1      (req)
    #  address2
    #  city          (req)
    #  state         (req)  Must be 2 character representation
    #  zip           (req)  Must be 5 digits
    #  label                Must be less than 50 characters
    #  
    # NOTE: If name is supplied, first_name and last_name are not required.
    #       Current payment processor requires first/last but we collect name 
    #       as a single field on the frontend. It's split by all characters 
    #       up to the first space being first_name and the rest is last name.
    def from_new_details(**details)
        if details[:name] && (!details[:first_name] || !details[:last_name])
            name = details[:name].split
            details[:first_name] = name.shift
            details[:last_name] = name.join(' ')
        end
        details[:label] = nil unless details[:label].present?
        validate_details(details)
        $LOG.info "New card details valid and set: [user: %s, details: %s]" % [ @user.email, censored(details) ]
        
        tokenized = verify_and_tokenize!(details)
        set_tokenized_details(tokenized)

        return self
    end

    # Verifies a credit card's details and returns its token for future payments
    # TODO: Figure out how to force failed response for UAT and write tests (manually feed it bad data)
    def verify_and_tokenize!(details)
        begin
            gateway_request_throttle_check
            
            response = @payment_gateway.tokenize(
                ActiveMerchant::Billing::CreditCard.new(
                    number:             details[:number],
                    verification_value: details[:verification],
                    month:              details[:exp_month].to_i,
                    year:               details[:exp_year].to_i,
                    first_name:         details[:first_name],
                    last_name:          details[:last_name]
                ), {
                    billing_address: {
                        address1: details[:address1],
                        address2: details[:address2],
                        city:     details[:city],
                        state:    details[:state],
                        zip:      details[:zip],
                    },
                }
            )

            gateway_log('Verify&Token', response)
        rescue StandardError => error
            $LOG.error error.message
            raise GatewayError, "Error returned from payment processor."
        end

        unless response.success?
            $LOG.debug "Rejection from payment gateway: [user: %s, response: %s]" %  [@user.email, response.inspect]
            raise GatewayRejection, "Invalid card response from provider. Please check your card info."
        end

        if response.params['TokenNumber'] == '0'
            $LOG.debug "Something wrong with your payment information: [user: %s, response: %s]" %  [@user.email, response.inspect]
            raise GatewayRejection, "Something wrong with your payment information. Please check your billing address or credit card information."
        end

        return {
            status:     response.params['TransactionStatus'],
            token:      response.params['TokenNumber'],
            pn_ref:     response.params['PNRef'],
            card_type:  response.params['CardType'],
            last_four:  response.params['LastFourOfCard'],
            exp_month:  response.params['ExpDate'][0...2],
            exp_year:   response.params['ExpDate'][2...4].to_i + 2000,
            label:      details[:label],
            first_name: details[:first_name],
            last_name:  details[:last_name],
            address1:   details[:address1],
            city:       details[:city],
            state:      details[:state],
            zipcode:    details[:zip],
        }
    end

    # Loads a chargeable credit card from json
    def from_json(json)
        begin
            from_hash(json.from_json)
        rescue InvalidDetails => error
            raise error
        rescue => error
            raise InvalidJson, "Error parsing JSON: [%s, %s]" % [error.message, json]
        end

        return self
    end

    # Loads a chargeable credit card from a hash (expects token, not actual CC)
    # TODO: Write tests
    # FIXME: Doesn't include card address
    def from_hash(hash)
        validate_expiration_date(hash[:exp_month], hash[:exp_year])

        set_tokenized_details(hash)

        return self
    end

    # Loads a chargeable credit card from a store model
    def from_model(model)
        raise InvalidModel, "Wrong type of model class: [%s, %s]" % [model.class, model.inspect] unless model.is_a?(CreditCard)
        raise InvalidDetails, "Card doesn't belong to user: [user: %s, model's user: %s]" % [@user.email, model.user.email] unless @user.id == model.user.id
        begin
            validate_expiration_date(model.month, model.year) 
        rescue InvalidDetails => error
            raise InvalidDetails, "#{error.message} [user: %s, card: %s]" % [@user.email, model.id]
        end

        set_tokenized_details({
            token:     model.info_key,
            pn_ref:    model.customer_key,
            card_type: model.type,
            last_four: model.last_four,
            exp_month: model.month,
            exp_year:  model.year,
            label:     model.label,
            address1:  model&.address&.address1,
            city:      model&.address&.city,
            state:     model&.address&.state,
            zipcode:   model&.address&.zipcode,
        })

        @model = model

        return self
    end

    # Returns a json object with tokenized details
    def to_json
        return to_hash.to_json
    end

    # Returns a hash with tokenized details
    def to_hash
        raise NotChargeable, "Unable to create hash because card not chargeable"  unless chargeable?

        return {
            token:           @token,
            pn_ref:          @last_pn_ref,
            card_type:       @card_type,
            last_four:       @last_four,
            exp_month:       @exp_month,
            exp_year:        @exp_year,
            label:           @label,
            card_address1:   @address1,
            card_city:       @city,
            card_state:      @state,
            card_zipcode:    @zip,
            card_address_id: @model&.address_id,
        }
    end

    # Returns a new (not saved) CreditCard model with tokenized details
    def to_model(context: 'StoreCard')
        raise NotChargeable, "Unable to create model because card not chargeable" unless chargeable?

        address = Address.new(
            table_name: 'credit_cards',
            active:     'Active',
            name:       "#{@first_name} #{@last_name}",
            address1:   @address1,
            city:       @city,
            state:      @state,
            zipcode:    @zipcode,
        )
        
        return CreditCard.new(
            user:         @user,
            info_key:     @token,
            customer_key: @last_pn_ref,
            type:         @card_type,
            last_four:    @last_four,
            month:        @exp_month,
            year:         @exp_year,
            created_by:   @user.id,
            created_with: context,
            label:        @label,
            address:      address,
        )
    end

    def charge!(amount)
        transact!(amount, type: 'charge')
    end

    def authorize!(amount)
        transact!(amount, type: 'authorize')
    end

    # Common method for performing transaction call
    # Accepted types: 'authorize' and 'charge'
    # TODO: Add tests
    def transact!(amount, type:)
        raise Error.new("Invalid transaction type: #{type}") unless type.among?('authorize', 'charge')    
        raise NotChargeable.new("Card not chargeable", user_message: "Error attempting to #{type} card. Please verify and try again.") unless chargeable?
        gateway_request_throttle_check

        if type == 'authorize'
            response = @payment_gateway.auth_with_token(amount, @token)
        elsif type == 'charge'
            response = @payment_gateway.purchase_with_token(amount, @token)
        end

        if response.success?
            $LOG.info "Succesfully #{type}d card: [token: %s, user: %s, amount: %.2f, response: %s]" % [@token, @user.email, amount, response.inspect]
            log_type = type == 'authorize' ? 'Auth' : 'Sale'
            gateway_log(log_type, response)
        else
            $LOG.debug "Unable to #{type} card: [token: %s, user: %s, amount: %.2f, response: %s]" % [@token, @user.email, amount, response.inspect]
            # raise GatewayRejection.new("Unable to #{type} card: #{response.inspect}", user_message: translate_error_code(response.params['Result']))

            raise GatewayRejection, "Unable to varify your card. Please try another card."
        end

        receipt = OpenStruct.new(
            success?:  response.success?,
            status:    response.params['TransactionStatus'],
            pn_ref:    response.params['PNRef'],
            auth_code: response.params['AuthCode'],
            last_four: response.params['LastFourOfCard'],
            amount:    amount,
            card_type: response.params['CardType'],
            type:      type,
        )

        $LOG.debug "{#type}d card and stored card's last four don't match: [stored: %s, charged: %s]" unless @last_four == receipt.last_four

        return receipt
    end

    def translate_error_code(code)
        PAYLEAP_ERROR_CODES.fetch(code.to_s, PAYLEAP_ERROR_CODES['unknown']).to_s
    end

    # This instance is chargeable is a token is set
    def chargeable?
        return !!@token
    end

    # Returns new censored hash
    def censored(hash)
        new_hash = hash.dup
        new_hash.each{ |k,v| new_hash[k] = CENSORED_REPLACEMENT if k.among?(CENSORED_FIELDS) }
    end

    # Checks if the user has hit their gateway throttle request quota
    def gateway_request_throttle_check
        count = PayleapLog.entry_count_since(THROTTLE_TIME.seconds.ago, user_id: @user.id)
        if count > THROTTLE_NUM
            $LOG.debug "Gateway throttle limit hit: [user: #{@user.email}]"
            raise GatewayThrottled.new("Gateway throttle limit hit.", user_message: :message)
        end
    end

    private
        # Validates card details
        # NOTE: See card detail fields in #from_new_details comment
        def validate_details(details)
            missing_details = REQUIRED_DETAILS - details.keys
            raise MissingDetails.new("Card details missing: [#{missing_details.join(', ')}]", user_message: :message) if missing_details.any?

            raise InvalidDetails.new("Card number not an integer value", user_message: :message) if details[:number] == 0
            raise InvalidDetails.new("Card number length not 16 digits", user_message: :message) if details[:number].to_s.length != 16

            validate_expiration_date(details[:exp_month], details[:exp_year])

            raise InvalidDetails.new("Card verification must be 4 or less digits", user_message: :message) if details[:verification].to_s.length > 4
            raise InvalidDetails.new("Card label is too long.", user_message: :message) if details[:label].to_s.length > 50
        end

        # Validates card expiration date
        def validate_expiration_date(month, year)
            begin
                expiration_date = Date.new(year.to_i, month.to_i).end_of_month 
            rescue => error
                raise InvalidDetails.new("Invalid expiration date: [#{month} / #{year}], Error: #{error.message}", user_message: :message)
            end

            raise InvalidDetails.new("Card expiration must be greater than today: [#{expiration_date}]", user_message: :message) if expiration_date < Date.today.end_of_month
        end

        # Sets instance details
        def set_tokenized_details(**t)
            @token       = t[:token]
            @last_pn_ref = t[:pn_ref]
            @card_type   = t[:card_type].capitalize
            @last_four   = t[:last_four].to_s
            @exp_month   = t[:exp_month].to_s
            @exp_year    = t[:exp_year].to_s
            @label       = t[:label]
            @first_name  = t[:first_name].to_s
            @last_name   = t[:last_name].to_s
            @address1    = t[:address1].to_s
            @city        = t[:city].to_s
            @state       = t[:state].to_s
            @zipcode     = t[:zipcode].to_s
        end

        # Creates a log entry in the database with a response from the gateway API
        # NOTE: `data` is assumed to be raw JSON by current implementation
        def gateway_log(action, data)
            PayleapLog.create_from_payleap_response(action, @user.id, data)
        end

end

# Singleton class to interact with our SAIL API service.
#
# Author: Jordan Ritter <jpr5@sdninc.co>

require 'httparty'

class SDN::SAIL < Module
    include ::HTTParty
    include ::Singleton

    module Exceptions
        class Error               < RuntimeError;    end
        class ConfigError         < Error;           end
        class InvalidConfig       < ConfigError;     end
        class ParametersError     < ArgumentError;   end
        class InvalidParameters   < ParametersError; end
        class SAILError           < Error;           end
        class SAILBadResponse     < SAILError;       end
    end
    include Exceptions

    attr_accessor :config

    const_def :CONFIG_FILE, "config/sail.yml"

    const_def :REQUIRED_KEYS_CREATE, [ :order_type, :delivery_method, :order_id, :site_id, :site_name, 
                                       :first_name, :last_name, :email, :address1, :address2, :city, 
                                       :state, :zipcode, :country ]

    def configure(file = nil)
        file ||= SDNROOT / CONFIG_FILE

        self.config = ::SDN::Config.load(file)

        unless [ :api_uri ].all? { |k| config.key? k }
            raise InvalidConfig, "config [#{config.inspect}] missing required params"
        end

        self.class.logger($LOG)
        self.class.base_uri config[:api_uri]

        $LOG.info "SAIL: configured for #{config[:api_uri]}"

        return true
    end

    # NOTE: Body should be a hash.
    # TODO: Confirm SAIL processes nested (multi-level) hashes properly on the other end.
    # FIXME: #get isn't converting body hash to query params
    def get(url, body, options = {})  self.class.get("/web/api" + url, options.merge(body: body))  end
    def post(url, body, options = {})  self.class.post("/web/api" + url, options.merge(body: body))  end
    def put(url, body, options = {})  self.class.put("/web/api" + url, options.merge(body: body))  end

    # Creates new customer
    # TODO: Add data validation for post
    # TODO: Add config validation
    # TODO: The created arrivy task ID should be saved to the order record (avoids future api lookups)
    def create_arrivy_task(post={})
        # Verify required fields
        required_keys = REQUIRED_KEYS_CREATE
        required_keys += [ :site_address ] if post[:delivery_method] == 'pickup'

        unless required_keys.all? { |k| post.key?(k) }
            raise InvalidParameters, "Missing required parameters: %s" % [ (required_keys - post.keys).join(',') ]
        end

        location = config[:locations][post[:site_id]] || config[:locations][:default]
        delivery_method = {
            'destage'         => 'DSTG',
            'destage_dropoff' => 'DROP',
            'pickup'          => 'PKUP',
            'delivery'        => 'DLVR',
        }.fetch(post[:delivery_method], 'DLVR')
        title = "%s-%s-%i-%s" % [ post[:order_type][0,1], delivery_method, post[:order_id], location ]
        template_id = config[:templates][post[:delivery_method].to_sym]
        group_id = config[:groups][post[:site_name].to_sym]

        payload = {
            external_id:            post[:order_id],
            title:                  title,
            unscheduled:            true,
            template:               template_id,
            group_id:               group_id,
            notifications:          { sms: false, email: false },
            customer_first_name:    post[:first_name],
            customer_last_name:     post[:last_name],
            customer_email:         post[:email],
            customer_mobile_number: post[:mobile_number],
            customer_company_name:  post[:company_name],
            extra_fields:           {}
        }
        payload[:is_destage] = post[:delivery_method].among?('destage', 'destage_dropoff')

        # The inconsistencies in how these fields are named is annoying.
        # TODO: Refactor this
        if post[:delivery_method].among?('pickup', 'destage_dropoff')
            # Sets primary address as site/warehouse address
            payload.merge!({
                customer_address_line_1: post[:site_address][:address1],
                customer_address_line_2: post[:site_address][:address2],
                customer_city:           post[:site_address][:city],
                customer_state:          post[:site_address][:state],
                customer_zipcode:        post[:site_address][:zipcode],
                customer_country:        post[:site_address][:country],
            })

            # Stuffs customer address into `additional_addresses`
            payload[:additional_addresses] ||= []
            payload[:additional_addresses] << {
                title:          'Staging Address',
                address_line_1: post[:address1],
                address_line_2: post[:address2],
                city:           post[:city],
                state:          post[:state],
                zipcode:        post[:zipcode],
                country:        post[:country],
            }
        else
            # Sets customer address as primary
            payload.merge!({
                customer_address_line_1: post[:address1],
                customer_address_line_2: post[:address2],
                customer_city:           post[:city],
                customer_state:          post[:state],
                customer_zipcode:        post[:zipcode],
                customer_country:        post[:country],
            })
        end

        # Adds extra delivery fields
        delivery_fields = post[:delivery_fields]
        payload[:extra_fields].merge!({
            'Dwelling Type':           delivery_fields[:dwelling],
            'Easily Accessed Parking': delivery_fields[:parking],
            'Number of Levels':        delivery_fields[:levels],
            'Special Considerations':  delivery_fields[:considerations],
            'Additional Information':  delivery_fields[:extra_information],
            'Special Assistance':      delivery_fields[:assistance],
            'On Site':                 delivery_fields[:onsite],
        }) if post[:delivery_method] == 'delivery'

        # Adds extra amount fields
        amount_fields = post[:amount_fields]
        payload[:extra_fields].merge!({
            'Order Total':          amount_fields[:order_total],
            'Rent Subtotal':        amount_fields[:order_subtotal],
            'Rent Tax Subtotal':    amount_fields[:tax_amount],
            'Rent Waiver Subtotal': amount_fields[:damage_waiver],
        })

        # Adds scheduling date
        # NOTE: This was originally only applicable to delivery orders, but now scheduling
        #       is added for both delivery and pickup orders.
        payload[:start_datetime] = post[:delivery_date].to_time.iso8601

        $LOG.debug "POST to SAIL /order/new with payload: %s" % [ payload.inspect ]
 
        response = self.post('/order/new', payload)

        if response.parsed_response['message'] == 'SUCCESS'
            $LOG.debug "SAIL responded with success."
            return true
        else
            $LOG.error "SAIL responded with error: %s" % [ response.inspect ]
            raise SAILBadResponse, "returned error response: [#{response.inspect}]"
        end
    end

    # Links a task to another task by our order ID
    # NOTE: task_id must be arrivy task ID and related_order_id is SDN order ID
    def link_arrivy_task(task_id, related_order_id)
        # TODO
    end

end

$SAIL = ::SDN::SAIL.instance

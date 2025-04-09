# Singleton class to contain our credentials and wrap the Avalara-specific class
# libraries.
#
# Author: Jordan Ritter <jpr5@sdninc.co>

require 'avatax'

require 'sdn/log'
require 'sdn/config'


class SDN::Avalara < Module
    include ::Singleton

    module Exceptions
        class Error         < RuntimeError; end
        class ConfigError   < Error;        end
        class InvalidConfig < ConfigError;  end
    end
    include Exceptions

    attr_accessor :config, :client

    const_def :CONFIG_FILE, "config/avalara.yml"

    def initialize
        # NOTE: nothing needed yet..
    end

    def configure(file = nil)
        file ||= SDNROOT / CONFIG_FILE

        self.config = ::SDN::Config.load(file)

        # validate config
        unless [ :username, :password, :endpoint ].all? { |k| config.key? k }
            raise InvalidConfig, "config [#{config.inspect}] missing required parameters"
        end

        config[:company_code] ||= "SDN"

        $LOG.info "Avalara: configured for acct #{config[:username]} in #{$CONFIG.env.upcase} mode"

        return true
    end

    def company_code
        config[:company_code]
    end

    def client
        @client ||= AvaTax::Client.new(config.merge(logger: !!config[:tracing]))
    end

    def reset
        @client = nil
        return self
    end

    def tracing?
        config[:tracing]
    end

    def tracing=(onoff)
        config[:tracing] = onoff
    end

    ##
    ## Primary Avalara API Methods
    ##

    def ping
        client.ping
    end

    # Returns: {"totalRate"=>0.101,
    #  "rates"=>
    #   [{"rate"=>0.065, "name"=>"WA STATE TAX", "type"=>"State"},
    #    {"rate"=>0.0, "name"=>"WA COUNTY TAX", "type"=>"County"},
    #    {"rate"=>0.036, "name"=>"WA CITY TAX", "type"=>"City"}]}
    def free_taxrate_for_zip(zipcode)
        client.tax_rates_by_postal_code({
            postalCode: zipcode,
            country: "US",
        })
    end

    # Gets a create transaction response used to parse address loc code/tax rate
    def dummy_transaction(address1, city, state, zipcode, date)
        date = DateTime.now if date == nil
        client.create_transaction({
            lines: [{
                number: 1,
                quantity: 1,
                amount: 100.00,
                taxCode: 'PS081282',
                itemCode: 'Y0001',
                description: 'Yarn',
            }],
            type: 'SalesInvoice',
            companyCode: 'SDN',
            date: date.strftime('%Y-%m-%d'),
            customerCode: 'ABC',
            purchaseOrderNo: date.strftime('%Y-%m-%d').to_s + '-001',
            addresses: {
                singleLocation: {
                    line1: address1,
                    city: city,
                    region: state,
                    postalCode: zipcode,
                },
            },
            commit: true,
            currencyCode: 'USD',
            description: 'Yarn',
        })
    end

    # Builds transaction from supplied order lines
    def create_transaction(order_lines, address, order_date=nil)
        order_date = DateTime.now unless order_date

        # Generate order lines from cart
        lines = []
        order_lines.each do |line|
            lines << {
                number: line[:id],
                quantity: 1,
                amount: line[:price],
                description: line[:product],
            }
        end

        # Create the transaction
        client.create_transaction({
            lines: lines,
            type: 'SalesInvoice',
            companyCode: 'SDN',
            date: order_date.strftime('%Y-%m-%d'),
            customerCode: 'NOTACUSTOMER',
            addresses: {
                singleLocation: {
                    line1: address[:line1],
                    city: address[:city],
                    region: address[:state],
                    country: address[:country] || 'US',
                    postalCode: address[:zipcode],
                },
            },
            commit: true,
            currencyCode: 'USD',
        })
    end

    # Returns: {"totalRate"=>0.101,
    #  "rates"=>
    #   [{"rate"=>0.065, "name"=>"WA STATE TAX", "type"=>"State"},
    #    {"rate"=>0.0, "name"=>"WA COUNTY TAX", "type"=>"County"},
    #    {"rate"=>0.036, "name"=>"WA CITY TAX", "type"=>"City"}]}
    def free_taxrate_for_address(zipcode:, state:"", city: "", address: "", country: "US")
        client.tax_rates_by_address({
            line1: address,
            city: city,
            region: state,
            postalCode: zipcode,
            country: country,
        })
    end

    # Fills a supplied TaxAuthority model with data from a /transaction/create response
    # Should this be here or in the model?
    def fill_tax_authority_model_with_transaction_response(r, ta)
        # TODO: Add validation for summary and other required fields
        state = r["summary"]&.find { |e| e["jurisType"] == "State" } || {}
        county = r["summary"]&.find { |e| e["jurisType"] == "County" } || {}
        city = r["summary"]&.find { |e| e["jurisType"] == "City" } || {}
        special = r["summary"]&.find { |e| e["jurisType"] == "Special" } || {}

        ta.description = (r["summary"]&.last&.fetch("jurisName", '') || '')
        ta.state_authority = state["jurisName"] || ''
        ta.state_rate = state["rate"]&.to_d || 0.0
        ta.county_authority = county["jurisName"]
        ta.county_rate = county["rate"]&.to_d || 0.0
        ta.city_authority = city["jurisName"]
        ta.city_rate = city["rate"]&.to_d || 0.0
        ta.special_authority = special["jurisName"]
        ta.special_rate = special["rate"]&.to_d || 0.0
        ta.total_rate = (ta.state_rate + ta.county_rate + ta.city_rate + ta.special_rate)
        ta.transaction_id = r["id"]
        ta.transaction_code = r["code"]
        ta.transaction_status = r["status"]
        ta.tax_rate_source = 'Avalara'

        return ta
    end

    # Gets the location code from /transaction/create response
    def get_location_code_from_transaction_response(r)
        if r['lines']&.first&.[]('details')&.first&.[]('serCode').present?
            # Get the serCode from lines[0]->details[0]->serCode, if it's set
            return r['lines']&.first&.[]('details')&.first&.[]('serCode').to_s.gsub(/^0+/, '')
        elsif r['summary']&.present?
            # Get last summary element's loc_code
            return r['summary']&.last['stateAssignedNo']
        else
            $LOG.error "Unable to get location code for #{r['id']}"
        end
    end

    # TODO: Figure out what we actually use in Avalara.php these days, and
    # incorporate here / in models.

    private

    def refcode(length = 8)
        ::SDN::Utils::RefCode.generate(length)
    end
end

$AVALARA = ::SDN::Avalara.instance
$AVALARA.send(:include, ::SDN::Avalara::Exceptions)

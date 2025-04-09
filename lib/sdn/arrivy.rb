# Singleton class to contain our credentials and handle authentication for us.
#
# Author: Jordan Ritter <jpr5@sdninc.co>

require 'httparty'

class SDN::Arrivy < Module
    include ::HTTParty
    include ::Singleton

    module Exceptions
        class Error               < RuntimeError;  end
        class ConfigError         < Error;         end
        class InvalidConfig       < ConfigError;   end
        class InvalidParameters   < ArgumentError; end
    end
    include Exceptions

    attr_accessor :config

    const_def :CONFIG_FILE, "config/arrivy.yml"

    def configure(file = nil)
        file ||= SDNROOT / CONFIG_FILE

        self.config = ::SDN::Config.load(file)

        unless [ :api_uri, :auth_key, :auth_token ].all? { |k| config.key? k }
            raise InvalidConfig, "config [#{config.inspect}] missing required params"
        end

        self.class.logger($LOG)
        self.class.format :json
        self.class.base_uri config[:api_uri]
        self.class.headers({
            'X-Auth-Key': config[:auth_key],
            'X-Auth-Token': config[:auth_token],
            'Content-Type': 'application/json',
        })

        $LOG.info "Arrivy: configured for #{config[:api_uri]}"

        return true
    end

    def get(url, body, options = {})  self.class.get("/api" + url, options.merge(body: body.to_json))  end
    def post(url, body, options = {}) self.class.post("/api" + url, options.merge(body: body.to_json)) end
    def put(url, body, options = {})  self.class.put("/api" + url, options.merge(body: body.to_json))  end

end

$ARRIVY = ::SDN::Arrivy.instance

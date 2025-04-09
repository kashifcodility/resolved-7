##
## (SDN) Application Configuration Loader
##

require 'yaml'
require 'socket'
require 'etc'
require 'sdn/utils'
require 'sdn/log'

module SDN
    class Config < Hash
        attr_accessor :env

        module Exceptions
            class Error         < RuntimeError; end
            class MissingConfig < Error       ; end
            class EmptyConfig   < Error       ; end
        end

        include Exceptions

        def initialize(file = nil, env = nil)
            super()

            @env    = (env || ENV['SDN_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development').to_sym
            @file   = file

            # TODO:  is this being used?
            @config = {}

            load(@file) if @file

            return self
        end

        def load(file)
            raise MissingConfig.new("can't find config file #{file}, try `rake config`") unless File.exists?(file) || File.exists?(file + ".global")

            # make sure we surface any exception due to invalid YAML
            yaml        = load_yaml(file)
            global_yaml = load_yaml(file + ".global")

            # Load the Global settings into the hash first
            self.deep_merge!(global_yaml[:default] || {})
            self.deep_merge!(global_yaml[self.env] || {})
            self.deep_merge!(global_yaml[:app] || {})

            # Merge the Local settings into the hash overriding globals
            self.deep_merge!(yaml[:default] || {})
            self.deep_merge!(yaml[self.env] || {})
            self.deep_merge!(yaml[:app] || {})

            raise EmptyConfig, "cannot load configuration #{file}: is empty" if self.empty?

            self
        end

        def all(scope = nil)
            scope ? self[scope] : self
        end

        class << self
            def load(*args)
                return self.new(*args)
            end
        end

        private
        def load_yaml(filename)
            begin
                # return empty hash if the file does not exist, this suppress all
                # failures due to nonexistent global configs
                return {} unless File.exists?(filename)
                ret = YAML::load(File.read(filename))
                # Empty yaml file
                return {} if ret == false
                unless ret.kind_of?(Hash)
                    raise "Configuration in #{filename} is NOT a hash... it is a #{ret.class.name}"
                end
                return ret.symbolize!
            rescue Exception => e
                # If the yaml file has invalid syntax, log the error
                if $LOG
                    $LOG.warn(e) { "failed to load config file #{filename}" }
                else
                    STDERR.puts "failed to load config file #{filename}"
                end

                raise e
            end
        end
    end
end

# By including this file, we auto-load the app config for you.  We
# *don't* freeze it so that you can override it later, if need be.
# Just don't be stupid about it.
$CONFIG = ::SDN::Config.load(Dir.pwd / 'config/app.yml')

# set some standard env-specific fields
$CONFIG[:hostname] = Socket.gethostname
$CONFIG[:username] = Etc.getlogin

$LOG.configure($CONFIG[:logging]) if $LOG and $CONFIG[:logging]

$LOG.info "#{$CONFIG[:name]} v#{$CONFIG[:version]} (#{$CONFIG.env.to_s.upcase}) loaded." if $LOG

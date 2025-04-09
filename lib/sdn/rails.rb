##
## General support modules for Rails 6.
##

require 'rails'
require 'action_controller/railtie'
require 'action_mailer/railtie'

# ExecJS auto-detects upon require, so we explicitly set the runtime and load
# ourselves before any of the extensions have a chance to (i.e. coffee-rails).
#ENV['EXECJS_RUNTIME'] = 'Node'
#require 'execjs'

#require 'jquery-rails' # see Jquery::Rails::JQUERY_VERSION and related constants
#require 'coffee-rails'
#require 'sass-rails'
#require 'bootstrap-rails'
#require 'uglifier'

module SDN
    module Rails

        autoload :Logging,    'sdn/rails/logging'
        autoload :Controller, 'sdn/rails/controller'
        autoload :Configurer, 'sdn/rails/configurer'
        autoload :Middleware, 'sdn/rails/middleware'
        autoload :Helpers,    'sdn/rails/helpers'

    end
end

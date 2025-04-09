# Framework is loaded via "rake test:env".
#
# Three jobs to this file:
#
#  (1) Load common deps, including helpers.
#  (2) Attach those helpers to places where we want to use them.
#  (3) Configure the RSpec environment, including before/after hooks (think: transactions)
#

# Common support/helper libs
require File.dirname(__FILE__) / "boot_common.rb"

# Extra RSpec support deps
require 'rspec/expectations'
require 'rspec/core/example_group'
require 'rspec/core/configuration'


class RSpec::Core::ExampleGroup
    include LogHelper::Framework
    include DatabaseHelper::Framework
    include PersonaHelper
    include SessionHelper
    #include RackHelper::Browser
    include Rack::Test::Methods
end


# When doing Sinatra unit tests, you want to get a namespace specifically for
# individual files or route sets; just putting your cases into Server#xxxx
# doesn't help isolate them.  Subclass from UnitTests for your general helpers,
# but from Urls to identify your individual url files.
if defined? Server
    class Server::UnitTests       < RSpec::Core::ExampleGroup; end
    class Server::UnitTests::Urls < Server::UnitTests;         end
end


#  config.around(:each) { |test| $DB.transaction(&test) }
RSpec.configure do |config|
    config.before :each do
        setup_transactional_test  # database_helper.rb
        setup_logging_test        # log_helper.rb

        # Reset the config each time (allows tests to screw with the config
        # object on each pass).  We save a copy rather than re-loading it from
        # file to speed things up a little.
        $ORIG_CONFIG = $CONFIG
        $CONFIG = $ORIG_CONFIG.clone
    end

    config.after :each do
        $CONFIG = $ORIG_CONFIG

        teardown_logging_test
        teardown_transactional_test
    end
end

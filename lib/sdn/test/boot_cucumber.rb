# Framework is loaded via "rake test:env"
#
# Three jobs to this file:
#
#  (1) Load common deps, including helpers.
#  (2) Attach those helpers to places where we want to use them.
#  (3) Configure the Cucumber environment, including before/after hooks (think: transactions)
#

# Common support/helper libs
require File.dirname(__FILE__) / "boot_common.rb"

# No extra cucumber deps so far..


class WorldClass
    include LogHelper::Framework
    include DatabaseHelper::Framework
    include RackHelper
    include PersonaHelper
    include SessionHelper
end

World do
    WorldClass.new
end


Before do
    setup_transactional_test
    setup_logging_test

    # Reset the config each time (allows tests to screw with the config object
    # on each pass).  We save a copy rather than re-loading it from file to
    # speed things up a little.
    $ORIG_CONFIG = $CONFIG
    $CONFIG = $ORIG_CONFIG.clone
end

After do
    $CONFIG = $ORIG_CONFIG

    teardown_logging_test
    teardown_transactional_test
end

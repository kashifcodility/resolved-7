###
### Standard SDN Application Initialization path.
###

##
## Envariable manipulation.
##

# First set the environment properly.
env = ENV['SDN_ENV'] || ENV['RUBY_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
ENV['RAILS_ENV'] = ENV['RACK_ENV'] = ENV['RUBY_ENV'] = ENV['SDN_ENV'] = env

# Then set the application root (SDNROOT).
SDNROOT = File.expand_path(File.dirname(__FILE__) + "/../")

# Next put the app's app, lib and vendor/lib dirs at the front of the path
# before loading any of our own dependencies.
LOAD_PATHS = [ "/app", "/lib", "/vendor/{gems/,}{*,*/*}/lib" ]
LOAD_PATHS.each do |path|
    $:.unshift(*Dir[SDNROOT + path].map { |d| File.expand_path(d) })
end
$:.unshift(SDNROOT)

# Lastly, we need to add in the paths of any GIT-based repos from bundler, if
# they exist.  This is because common dependencies may be specified but loaded
# via this mechanism, which means anything GIT needs to be in the path before
# the bundler gem is loaded or it won't work (and in some cases, we may not load
# with bundler at all).
if rbenv_root = `rbenv prefix`.chomp
    bundler_root = rbenv_root + '/lib/ruby/gems/2.6.0/bundler/gems'
    Dir["#{bundler_root}/*/lib"].each do |path|
        $:.unshift(path)
    end
end

# And as a helper, determine if we're in RAILS.
RAILS_GEM_VERSION = '6.0.0' if File.exists?(SDNROOT + '/config/routes.rb')

##
## Start loading the various initialization mechanisms.
##

# "gems" defangs RubyGems for us, shielding us from other 3rd party gems that
# use it indiscriminately, and loads any single-version system-gems into the
# LOAD_PATH for us (leaving RubyGems to handle only cases where multiple
# versions of the same gem are installed).
require 'rubygems'
require 'sdn/gems'

# Load common dependencies.
require 'pry'
require 'byebug'
require 'base64'
require 'json'
require 'i18n'

# HACK: There is a bug in ActiveSupport whereby it wipes its own instance
# methods out on class definition and breaks upon instantiation (self#require).
# Usually we'd want to get the last laugh when patching, but in order to fix
# this bug we have to get there first, so we explicitly load this patch ahead of
# time.  Specifying full path prevents the Patch Loader from loading it again.
require 'sdn/patches/as_deprecation_proxy'
require 'active_support'

# Rails 1st stage: initialize the Rails framework and load desired railties
# (which makes available their configuration directives).
if Object.const_defined?(:RAILS_GEM_VERSION)
    require 'sdn/rails'
end

require 'sdn/mixins'

# Then load application-local bootstrap routines (generally dependencies).  We
# roll our own instead of riding 'config/environment' for when we're not booting
# rails (sinatra, daemon).

require 'bundler/setup'
Bundler.setup

require 'config/deps'

if Object.const_defined?(:RAILS_GEM_VERSION)
    Rails.logger = $LOG
    require 'config/environment' unless $BOOTED_FROM_RAILS # brings Rails.config into being
end

# LAST: Load up our last-laugh patch loader.  *Must* always be last.
require 'sdn/patches'

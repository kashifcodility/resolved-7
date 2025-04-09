require 'boot/init'

# Detect and override rackup default options.
#
# Find the server's options Hash and let non-default cmdline arguments override
# YAML configuration.  Then configure Sinatra.
#
# Setting the environment to "none" prevents Rack from installing any default
# middlewares.
case Rack::VERSION
when [1, 1], [1, 2], [1, 3] then
    options = nil
    ObjectSpace.each_object(Rack::Server) do |c|
        raise "** WARNING: more than one rack server instance detected" if options
        options = c.options
    end

    raise "** FATAL: unable to find the rack server instance" unless options
end

host = options[:Host] if options[:Host] != "0.0.0.0"
port = options[:Port] if options[:Port] != 9292
host ||= $CONFIG[:host] || options[:Host]
port ||= $CONFIG[:port] || options[:Port]
options[:Host] = $CONFIG[:host] = host
options[:Port] = $CONFIG[:port] = port

# In Rack 1.0x, options hash exists but ''env'' is used instead.  Shorter to do
# this than conditionalize the assignment.
env = options[:environment] = "none"

$NEWRELIC.boot! if $CONFIG[:enable_newrelic]

$LOG.info "#{$CONFIG[:name]} listening on #{options[:Host]}:#{options[:Port]}"

#run ::ActionController::Dispatcher.new
run Rails.application

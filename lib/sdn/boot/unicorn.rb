##
## Unicorn
##

$:.unshift "."

# This is equivalent to 'preload_app true', technically speaking,
# where unicorn's assumption is that config.ru would have loaded your
# app framework.  Since we want unicorn et al. using some things we
# provide (e.g. logging), we must preload ourselves.
require 'boot/init'

logger $LOG

$CONFIG[:unicorn] ||= {}
defaults =
    case $CONFIG.env
    when :production then
    {
        :timeout  => 60,
        :workers  => 20,
        :root     => "/srv/src/apps/#{$CONFIG[:name]}",
    }
    else
        # In all other cases (test, dev, etc) set a large timeout in case we go into
        # a debugger or something, and set default pool size to 1.
    {
        :timeout => 5000000,
        :workers => 1,
        :root    => File.expand_path(File.dirname(__FILE__) / ".."),
    }
    end

config = $CONFIG[:unicorn] = defaults.merge($CONFIG[:unicorn])

working_directory config[:root]
worker_processes  config[:workers]
timeout           config[:timeout]

# Set the default location for unicorn to write pid file. Unicorn pid file is
# necessary to identify the unicorn master for a particular app.
if file = $CONFIG[:pid_file]
    FileUtils.mkdir_p(File.dirname(file))
    pid file
end

# Now figure out if there's been a cmdline override wrt listeners - cmdline
# parameters always override anything in the config files.
#
# There should be 0 <= self[:listeners] <= 1, so if one is present at this early
# stage then it represents an override.  We have to make an assumption here that
# listeners without ':'s are unix-oriented, even though you can put :'s in
# pathnames.  Oh well, suckit.
#
# NOTE: The TCP "defaults parsing" logic here is meant to be a comparable analog
# to common/boot/{rails,rack}.ru.  If you change it here, please change it in
# those two places also.

ENV['ARGS'].split(/ /).each_slice(2) do |switch, value|
    case switch
    when '-o' then $CONFIG[:host] = value
    when '-p' then $CONFIG[:port] = value
    end
end rescue nil

# Unless a UNIX socket came out of all of this, then by default listen on TCP.
# This should catch the case where we're running in production and don't want a
# TCP socket at all.
unless $CONFIG[:sock]
    $CONFIG[:host] ||= "0.0.0.0"
    $CONFIG[:port] ||= "9292"
end

listen "#{$CONFIG[:host]}:#{$CONFIG[:port]}" if $CONFIG[:host] and $CONFIG[:port]
listen $CONFIG[:sock]                        if $CONFIG[:sock]

Unicorn::Configurator::RACKUP[:set_listener] = false
Unicorn::Configurator::RACKUP[:no_default_middleware] = true

before_fork do |server, worker|
    # Shut down any DB connections we may have started (verify table/model
    # existence) so we don't bork shared file descriptors.
    DataObjects::Pooling.pools.each(&:dispose) if defined? DataObjects

    # Handle pidfile, if one is set + we're not already in "oldbin" mode (master
    # dying off) + the pid file is still there.
    next unless server.pid
    next if     server.pid =~ /oldbin$/

    old_pidfile = server.pid + '.oldbin'
    next unless File.exists?(old_pidfile)

    old_pid     = File.read(old_pidfile).to_i

    $LOG.warn "killing master pid #{old_pid}"

    begin
        Process.kill("QUIT", old_pid)
    rescue Errno::ENOENT, Errno::ESRCH
        $LOG.warn "unable find master pid #{old_pid} to kill"
    end
end

after_fork do |server, worker|
    srand

    # reconfigure logger after fork so that worker's log shows correct PID
    $LOG.configure($CONFIG[:logging])

    ::Server.boot! if defined? ::Server
end

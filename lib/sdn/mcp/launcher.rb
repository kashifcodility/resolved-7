require 'optparse'

require 'sdn/log'
require 'sdn/config'

require 'sdn/mcp/overwatch'
require 'sdn/mcp/daemon'

module MCP
    class Launcher
        attr_accessor :config

        # FIXME: This method should be DRY'd up.
        # FIXME: *Seriously*.
        def initialize
            @config = {
                :config_file => 'config/launcher.yml',
                :daemonize   => false,
                :overrides   => {},
            }

            parse_cmd_line(@config)

            if File.exists?(@config[:config_file])
                @config = ::SDN::Config.load(@config[:config_file]).merge(@config)
                $LOG.info "launching daemons specified in #{@config[:config_file]}"
            end

            unless @todo_list = @config[:daemon]
                # Fallback: If there is no launcher config for us (:daemon stanza),
                # we might be running inside a daemon's folder, whose config might
                # contain a 'workers' reference for us.
                daemon_name   = File.basename(File.expand_path("."))
                daemon_config = ::SDN::Config.new("config/app.yml")
                num_workers   = daemon_config[:workers] || 1
                @config[:logging] = daemon_config[:logging] if daemon_config[:logging]

                @todo_list = [ {:name => daemon_name, :workers => num_workers} ]
            end

            $LOG.configure(@config[:logging]) if $LOG and @config[:logging]

            $CONFIG.deep_merge!(@config)

            # Overwatch is a wrapper over Unicorn Horn.  It provides an
            # interface to adding daemon instances and uses Unicorn Horn to run
            # the daemons.
            @overwatch = Overwatch.new(@config[:overrides])

            @todo_list.each do |todo|
                unless daemon_name = todo[:name]
                    $LOG.error "missing daemon name in config #{todo.inspect}, IGNORING"
                    next
                end

                if todo[:tag] == 'disabled'
                    $LOG.error "daemon #{daemon_name} is disabled, SKIPPING"
                    next
                end

                if @config[:launch_tag]
                    unless todo[:tag]
                        $LOG.error "daemon #{daemon_name} missing tag in config #{todo.inspect}, IGNORING"
                        next
                    end

                    if todo[:tag] != @config[:launch_tag]
                        $LOG.info "Daemon #{todo[:name]} has tag #{todo[:tag]}, not matching #{@config[:launch_tag]}, IGNORING"
                        next
                    end
                end

                daemon_path = File.expand_path('../' + daemon_name)

                # global config defined in the launcher config, can be
                # overwritten by daemon-specific config
                global_config = {}
                global_config[:notifier] = @config[:notifier] if @config[:notifier]
                daemon = Daemon.instantiate(daemon_name, daemon_path, nil, global_config)

                # TODO, find a better solution for config override
                daemon.configure(@config[:overrides])
                if todo[:config]
                    daemon.configure(todo[:config])
                end

                unless daemon.valid_config?
                    $LOG.error "#{daemon_name} has an invalid configuration"
                    if @config[:ignore_invalid_config] && @config[:ignore_invalid_config].to_s.downcase == 'true'
                        $LOG.error "IGNORING"
                        next
                    end
                    # not ignoreing invalid config
                    $LOG.error "Exiting"
                    exit -1
                end

                # Override worker # with something set from the cmdline, if present.
                @overwatch.add(daemon, @config[:workers] || todo[:workers])
            end
        end

        def start
            # Launch each daemon, and wait around until one dies.  Re-launch it and
            # repeat.
            daemonize if @config[:daemonize]

            @overwatch.run
        end

        def parse_cmd_line(config)
            ::OptionParser.new do |opts|
                opts.on('-d', '--daemonize', 'Run in background') do |daemon|
                    config[:daemonize] = true
                end

                # put the config overrides in the config_overrides hash, need to pass to daemons
                opts.on('-c', '--config CONFIG', 'Override config options with yaml_name.key_name.subkey_name=value pairs') do |c|
                    # split on = to get keys/value
                    match_data = c.match(/(.*)=(.*)$/)

                    # keys needs to be an array...
                    keys  = match_data[1].split(".")
                    value = match_data[2]

                    # create a nested hash with the keys, making sure the keys are symbols
                    # keys are split by '.'
                    config[:overrides].merge!(keys.reverse.inject(value){ |v, k| v = {k.to_sym => v} })
                end

                opts.on('-w', '--workers NUM', 'Number of workers') do |worker_number|
                    $LOG.info "setting number of workers to #{worker_number}"
                    config[:workers] = worker_number
                end

                opts.on('-t', '--tag TAG', 'Launcher daemon with specified tag') do |tag|
                    $LOG.info "Only launching daemons with tag #{tag}"
                    config[:launch_tag] = tag
                end

                opts.on('-l', '--launcher-config-file FILE', 'Launcher config file to use') do |f|
                    config[:config_file] = f
                end
            end.parse!

            return config
        end

        def daemonize
            if Process.fork
                # in parent process, parent should exit
                # no way to determine if the fork succeeds
                exit
            else
                # in child process
                # reopen inherited STDs to detach from old tty (to allow ssh to exit)
                STDIN.reopen('/dev/null')
                STDOUT.reopen('/dev/null', 'w')
                STDERR.reopen('/dev/null', 'w')
            end
        end
    end
end

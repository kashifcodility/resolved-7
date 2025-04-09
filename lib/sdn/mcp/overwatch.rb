require 'sdn/mcp/named_proc'
require 'sdn/mcp/runner'

module MCP
    class Overwatch
        attr_accessor :name

        def initialize(config_overrides)
            @name = "mcp: overwatch"
            @forks = [] # hash from class name to a hash containing class, pid and status
        end

        def add(daemon_instance, num_workers = nil)
            @forks << {
                :daemon_instance => daemon_instance,
                :num_workers     => (num_workers || 1).to_i,
            }
        end

        def run
            $LOG.info "#{name} is starting up"
            to_launch = []

            @forks.each do |daemon_fork_config|
                daemon_instance = daemon_fork_config[:daemon_instance]
                num_workers     = daemon_fork_config[:num_workers]
                daemon_name     = daemon_instance.name
                worker_id       = 1

                num_workers.times do
                    proc_to_launch = NamedProc.new do
                        daemon_instance.run
                    end
                    proc_to_launch.set_name("mcp: #{daemon_name} slave #{worker_id}")
                    worker_id += 1
                    to_launch << proc_to_launch
                end
            end

            # Main run loop for Overwatch.
            @runner = Runner.new(to_launch)
            @runner.name = @name
            @runner.run

            $LOG.info "#{name} is calling it quits"
        end
    end
end

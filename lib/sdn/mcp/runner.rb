require 'sdn/mcp/self_pipe_daemon'
require 'sdn/mcp/worker'

module MCP
    class Runner < SelfPipeDaemon

        def initialize(handlers)
            super()
            @workers = handlers.map{ |handler| Worker.new handler }
        end

        def run
            register :QUIT, :INT, :TERM, :CHLD, :HUP
            @workers.each { |w| w.launch! { reset } }

            ploop do |signal|
                reap
                case signal
                when nil
                    @workers.each{ |w| w.wpid or w.launch! }
                    psleep 1
                when :CHLD then       next
                when :HUP  then       raze(:QUIT,  5);
                when :TERM, :INT then raze(:TERM,  3); break
                when :QUIT then       raze(:QUIT, 60); break
                end
            end
        end

        def reset
            @workers.clear
            forget
        end

        private

        def reap
            begin
                wpid, status = Process.waitpid2(-1, Process::WNOHANG)
                wpid or return
                next unless worker = @workers.detect{ |w| w.wpid == wpid }
                worker.reap(status)
            rescue Errno::ECHILD
                break
            end while true
        end

        def raze(sig, timeframe)
            limit = Time.now + timeframe
            until @workers.empty? || Time.now > limit
                @workers.each{ |w| w.kill(sig) }
                sleep(0.1)
                reap
            end
            @workers.each{ |w| w.kill(:KILL) }
        end

    end
end

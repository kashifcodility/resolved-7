# Idea is to capture every LOG call so specs & cukes can verify the kind of
# logging done by various error cases.  Now we take advantage of "monitor"
# functionality in $LOG to accomplish this easily.

module SDN
    class LogMonitor

        private

        attr_accessor :messages, :ring_size, :mutex

        public

        def initialize(size = 256)
            self.messages  = []
            self.ring_size = size
            self.mutex     = Mutex.new
        end

        def capture(severity, message)
            mutex.synchronize do
                messages.shift if messages.length >= ring_size
                messages << "#{severity.upcase} : #{message}"
            end
        end

        def grep(*args) mutex.synchronize { messages.grep(*args) } end
        def clear()     mutex.synchronize { messages.clear } end
    end
end

module LogHelper
    module Framework
        def setup_logging_test
            # clear the log
            $LOG.monitor.clear
        end

        def teardown_logging_test
            # no-op
        end


        def log_should_contain(level_name, message = nil, count = nil)
            lines = $LOG.monitor.grep(Regexp.new(level_name.upcase))
            if message
                regexp = (message.is_a?(Regexp) && message) || Regexp.new(message.to_s)
                lines = lines.grep(regexp)
            end

            if count
                lines.length.should(be_equal(count), "message = #{message.inspect}, count = #{count}")
            else
                lines.length.should_not(be_equal(0), "message = #{message.inspect}")
            end
        end

        def log_should_not_contain(level_name, message = nil)
            log_should_contain(level_name, message, 0)
        end

        def log_should_contain_error(*args)
            log_should_contain(*args.unshift('error'))
        end
        def log_should_contain_info(*args)
            log_should_contain(*args.unshift('info'))
        end

        def log_should_not_contain_error(*args)
            log_should_not_contain(*args.unshift('error'))
        end
        def log_should_not_contain_info(*args)
            log_should_not_contain(*args.unshift('info'))
        end
    end
end

$LOG.monitor = ::SDN::LogMonitor.new

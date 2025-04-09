require 'sdn/log'

class SDN::Log
    class Formatter < ::Logger::Formatter

        def initialize
            super
            @formatters = []
        end

        def call(severity, time, progname, msg)
            pid  = Process.pid
            name = $CONFIG[:name]

            time     &&= time.strftime("%Y-%m-%d %H:%M:%S")
            progname ||= "%s[%s]" % [ name, pid ]

            self.formatters.each do |formatter|
                formatter.call(severity, time, progname, msg)
            end

            "%s %5s %s %s" % [ time, severity, progname, msg ]
        end

        def add(formatter)
            formatter = Formatters.const_get(formatter.to_s.classify)
            return true if @formatters.include?(formatter)
            return false unless formatter.supported?
            @formatters << formatter
        rescue
            return false
        end

        def reset
            @formatters.clear
        end

        protected

        attr_accessor :formatters
    end

    module Formatters
        def self.extended(klass)
            def klass.supported?() true end
        end

        module Thread
            extend Formatters

            def self.call(severity, time, progname, msg)
                progname.insert(-1, " {#{::Thread.current.inspect}}")
            end
        end

        module Location
            extend Formatters

            # Gets both Framework logger and ruby built-in logger.
            const_def :LOG_PATHS,
                      [ "log/filter", "log/formatter", "log(|ger)" ]

            const_def :LOG_PATH_RE,
                      Regexp.new("(#{LOG_PATHS * '|'}).rb:")

            # Previous incarnation was to search for the first entry that
            # matched "app/", however this would miss framework files.
            #
            # To correct that, we now "find the first non-log-related caller"
            # (since caller from here is always the logger), convert to string
            # (nil.to_s == ""), get the basename of the path, strip out the
            # method caller (if present!), and prefix the msg with the result.
            #
            # Sometimes the "first non-log-related caller" is a closure.  Since
            # that's not helpful, we avoid those too.
            def self.call(severity, time, progname, msg)
                location = caller.find  do |c|
                    c.match(LOG_PATH_RE) == nil and c.match('(eval)') == nil
                end.to_s

                base = File.basename(location.sub(/:in .+$/, ''))

                msg.insert(0, base + " ")
            end
        end

        # NOTE: Beware, this is expensive.
        #
        # TODO: does this work on Linux?  if not, make supported? => false in
        # that case.
        module Memory
            extend Formatters

            def self.call(severity, time, progname, msg)
                current_memory = `ps -o rss= -p #{Process.pid}`.to_i
                memory_delta = current_memory - (@previous_memory || current_memory)
                @previous_memory = current_memory
                msg.insert(0, "%6s %4s " % [current_memory, memory_delta])
            end

            def self.supported?
                return RUBY_PLATFORM !~ /mingw32/
            end
        end

        module Color
            extend Formatters

            # Doesn't have to be limited to just SQL, but is for now.  Sort
            # longest to shortest so any keywords that match sub-portions of
            # others display properly (i.e. OR vs. ORDER).
            const_def :SQL_KEYWORDS, %w[
                SELECT FROM INSERT INTO UPDATE DELETE
                WHERE AND OR IN DESC LIMIT OFFSET GROUP ORDER BY HAVING
                INNER OUTER LEFT RIGHT JOIN ON
                TRANSACTION START COMMIT ROLLBACK BEGIN END
                BETWEEN SET SESSION
            ].sort_by(&:length).reverse

            const_def :SQL_KEYWORD_RE, Regexp.new("\\b(#{ SQL_KEYWORDS.join("|")})\\b")

            const_def :COLORS, {
                'DEBUG' => "\e[38;5;246m",
                'INFO'  => "\e[38;5;253m",
                'WARN'  => "\e[38;5;011m",
                'ERROR' => "\e[38;5;009m",
                'FATAL' => "\e[1m\e[38;5;009m",
            }

            const_def :KEYWORD_COLOR, "\e[38;5;081m";
            const_def :RESET_COLOR,   "\e[0m";

            def self.call(severity, time, progname, msg)
                log_color = COLORS[severity]
                msg.gsub!(SQL_KEYWORD_RE, "#{KEYWORD_COLOR}\\1#{log_color}")
                msg.replace("#{log_color}#{msg}#{RESET_COLOR}")
            end

            # NOTE: win32console fucks up Ruby's internal encoding mechanism.
            # This is primarily to do with replacing $stdout with its own class.
            # In any case, win32console is deprecated in favor of the TSR-like
            # ANSICON library (which doesn't require any gem).  Deferring for
            # now.
            def self.supported?
                return RUBY_PLATFORM !~ /mingw32/
=begin
                 require 'win32console' if RUBY_PLATFORM =~ /mingw32/
                 return true
=end
            rescue LoadError
                return false
            end
        end
    end
end

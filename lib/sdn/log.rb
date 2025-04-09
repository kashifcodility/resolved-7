##
## SDN Logger
##
## This library implements:
##
##   (1) timestamp, program, and pid on every message
##   (2) emission to STDOUT (in addition to log) when in dev mode
##   (3) emission to file ala ruby's Logger
##   (4) emission to syslog both locally (unix socket) and remote (UDP)
##   (5) integrated rack adapter for apache-style logging

require 'logger'
require 'sdn/utils'
require 'active_support/core_ext/time'

module SDN

    # Simple instance that translates log calls to either a socket or the Syslog constant.
    class Syslogger

        # Log levels
        %w[ EMERG ALERT CRIT ERR WARNING NOTICE INFO DEBUG ].each_with_index do |prio, i|
            const_def("LOG_#{prio}", i)
        end

        # Options
        %w[ PID CONS ODELAY NDELAY NOWAIT PERROR ].each_with_index do |opt, i|
            const_def("LOG_#{opt}", 1 << i)
        end

        # Facilities
        %w[ KERN     USER   MAIL    DAEMON     AUTH
            SYSLOG   LPR    NEWS    UUCP       CRON
            AUTHPRIV FTP    NETINFO REMOTEAUTH INSTALL
            RAS      LOCAL0 LOCAL1  LOCAL2     LOCAL3
            LOCAL4   LOCAL5 LOCAL6  LOCAL7 ].each_with_index do |facility, i|
            const_def("LOG_#{facility}", i << 3)
        end

        attr_reader   :facility
        attr_accessor :host
        attr_accessor :identity
        attr_accessor :socket
        attr_writer   :path

        def initialize(opts={})
            opts.each do |key, value|
                send("#{key}=",value)
            end
            return open
        end

        def host=(host)
            require 'resolv'
            @host = Resolv.new.getaddress(host) rescue nil
        end

        def open
            self.close if self.opened?

            if self.host
                self.socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
                sockaddr = Socket.pack_sockaddr_in(514, self.host)
            else
                self.socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_DGRAM, 0)
                sockaddr = Socket.pack_sockaddr_un(self.path)
            end

            self.socket.connect(sockaddr)
        end

        def opened?
            self.socket && !self.socket.closed?
        end

        def close
            self.socket && !self.socket.closed? && self.socket.close && self.socket = nil
            return self
        end

        def facility=(value)
            if value.is_a?(String) or value.is_a?(Symbol)
                @facility = self.class.const_get(value.to_sym)
            else
                @facility = value
            end
        end

        def log(severity, message)
            begin
                self.socket.write("<#{severity|facility}>#{identity} #{message}")
            rescue Errno::ENOTCONN, Errno::ECONNREFUSED, Errno::ECONNABORTED => e
                return if (Thread.current[:syslog_reconnects] ||= 0) > 2
                STDERR.puts "lost connection to syslog; reconnecting [#{Thread.current[:syslog_reconnects]}] #{e.message}"
                Thread.current[:syslog_reconnects] += 1
                self.open
                retry
            rescue => e
                STDERR.puts "Failed to write to Syslog: #{e.class} - #{e.message} #{e.backtrace.inspect}"
            ensure
                Thread.current[:syslog_reconnects] = 0
            end
        end

        def path
            return @path ||=
                case RUBY_PLATFORM
                when /darwin/ then '/var/run/syslog'
                when /linux/  then '/dev/log'
                else "unsupported on #{RUBY_PLATFORM}"
                end
        end
    end

    class Log < ::Logger

        ##
        ## Constants and Class variables
        ##

        protected

        # Defang multi-line and colorized log messages (which might screw up something
        # like syslog).
        def clean_msg(msg)
            msg.gsub(/\n/, '').gsub(/\033\[[\d;]*[A-Za-z]/,'')
        end

        # SYSLOG_PRIORITY_MAP must have a mapping for every possible
        # ::Logger level.
        const_def :SYSLOG_PRIORITY_MAP,
        {
            ::Logger::UNKNOWN => ::SDN::Syslogger::LOG_WARNING,
            ::Logger::DEBUG   => ::SDN::Syslogger::LOG_DEBUG,
            ::Logger::INFO    => ::SDN::Syslogger::LOG_INFO,
            ::Logger::WARN    => ::SDN::Syslogger::LOG_WARNING,
            ::Logger::ERROR   => ::SDN::Syslogger::LOG_ERR,
            ::Logger::FATAL   => ::SDN::Syslogger::LOG_EMERG,
        }

        ##
        ## Methods
        ##

        public

        # convenience methods per logging level
        const_def :LEVEL_CONVENIENCE_METHODS, %w{ debug info warn error fatal }.collect(&:to_sym)

        attr_accessor :mutex, :syslogger, :monitor

        def initialize(level = Log::DEBUG, logdev = nil)
            self.monitor = nil
            self.mutex   = Mutex.new
            @formatter   = Log::Formatter.new

            configure({:level => level, :console => true})
        end

        def open(filename)
            @logdev.close if @logdev
            @logdev = LogDevice.new(filename, :shift_age => 0)
        end

        # SDN::Log#configure expects to be passed a hash that would be typically
        # be under "logging:".  We can get called as a (re)configure, so could
        # be either opening or closing logs.

        def configure(config)
            config = config.is_a?(Hash) ? config.dup : ::SDN::Config.load(config)[:logging]

            mutex.lock

            config.each_pair do |k, v|
                case k
                when :console then
                    unless v.among?(true, false)
                        next self.error "unknown logging console directive: #{v.inspect}"
                    end

                    @console = v

                when :level then

                    # Transform value into a digit (Logger::Severity::CONSTANT).
                    # Might come in as a string or a symbol, so prep for lookup.
                    v = case v
                    when Symbol, String then Log::Severity.const_get(v.to_s.upcase) rescue nil
                    when Integer then v
                    else nil
                        end

                    next self.error "unknown logging level directive: #{v.inspect}" unless v

                    @level = Thread.current[:sdn_log_level] = Thread.main[:sdn_log_level] = v

                when :syslog then

                    if @syslogger
                        @syslogger.close if @syslogger.opened?
                        @syslogger = nil
                    end

                    next unless v

                    # Facility only
                    #     syslog: LOG_LOCAL6
                    #
                    # Facility and host
                    #     syslog: LOG_LOCAL6
                    #     host: syslogger.int.cloudcrowd.com

                    facility = v
                    host = config[:host]

                    unless facility.to_sym.among?(SDN::Syslogger.constants)
                        next self.error "unknown logging facility #{v.inspect}"
                    end

                    @syslogger = ::SDN::Syslogger.new({
                            :facility => facility,
                            :host     => host,
                            :identity => "%s[%s]" % [$CONFIG[:name], Process.pid],
                        })

                when :file then
                    open(v)

                when :host then
                    # NOOP: used in syslog above, defined to prevent triggering error.

                when :formatters then
                    # Purge existing filters if the config is false or empty,
                    # otherwise add them in.  Supports both single and array
                    # forms.
                    if v.blank? # nil, false, empty
                        @formatter.reset
                    else
                        Array(v).each do |format|
                            unless @formatter.add(format)
                                next self.error "unable to enable logging formatter #{format.inspect}"
                            end
                        end
                    end

                else
                    next self.error "unknown logging directive #{k} (#{v.inspect})"
                end

            end

        ensure
            mutex.unlock
            return self
        end

        def level
            Thread.current[:sdn_log_level] || Thread.main[:sdn_log_level] || 0
        end

        def level=(_level)
            configure({:level => _level})
        end

        def console() @console end
        def console=(_console)
            configure({:console => _console})
        end

        # Override add() so we can do Syslog and STDOUT logging.
        def add(severity, message = nil, progname = nil)
            return if severity < self.level

            progname ||= @progname
            unless message
                if block_given?
                    begin
                        message = yield
                    rescue => e
                        $LOG.error(e) { "log handler threw an exception while evaluating block" }
                        return
                    end
                else
                    message = progname
                    progname = @progname
                end
            end

            # order of ops:
            # (1) output to console unmodified (if configured)  - catch level and non-level (<<)
            # (2) output to file   [cleaned]                    - catch level and non-level (<<)
            # (3) output to syslog [cleaned] (if configured)    - level required (add)

            # Beware the cost of Time.now..
            # since the filters perform inplace string update,
            # need make a copy so that we do not modify variables passed in
            Time.zone ||= 'Pacific Time (US & Canada)' # TODO: Move this to a config
            self << formatter.call(format_severity(severity), Time.zone.now, progname, message.dup)

            # FIXME: Following is a duplicate call to clean_msg() (first one occurred in
            # << above), find a way to factor it back down to one.
            #
            # This is because syslog has to be called from the add() scope (it needs to
            # know the priority), whereas console (STDOUT) and file (format_message) get
            # called from <<() because the time+priority is already formatted onto the
            # string.  However, there's no way to communicate the originally cleaned
            # string back up to this scope without changing the return value of << (which
            # we want to keep consistent as "self").

            @syslogger.log(SYSLOG_PRIORITY_MAP[severity], clean_msg(message)) if @syslogger && @syslogger.opened?
        ensure
            return self
        end

        def <<(msg)
            # First log to STDOUT if console is enabled, then write the message to
            # Logger's logdev if one is open.
            synchronize { Kernel.warn(msg) } unless @console == false
            @logdev.write(clean_msg(msg) + "\n") if @logdev
        ensure
            return self
        end
        alias puts <<

        # Variant of << meant only for low-ass level shit.
        def puke
            synchronize { Kernel.warn(msg) } unless @console == false
        ensure
            return self
        end

        # NEW: These are now thread-safe (since current log level is stored in
        # thread-local storage.
        def quietly(&block)
            with_level(::SDN::Log::INFO, &block)
        end

        def silently(&block)
            with_level(::SDN::Log::FATAL, &block)
        end
        alias_method :silence, :quietly

        def with_level(level)
            return unless block_given?
            save_level = self.level
            Thread.current[:sdn_log_level] = level
            return yield
        ensure
            Thread.current[:sdn_log_level] = save_level
        end

        # Front-end all the standard calls to add optional exception-passing
        # support.  This is mainly meta-programmed so we can call super().
        #
        # Supported use-cases:
        #   $LOG.error "balls"
        #   $LOG.error(e)
        #   $LOG.error(e) { "balls" }
        #   $LOG.error(e, :depth => 10) { "balls" }
        LEVEL_CONVENIENCE_METHODS.each do |meth|
            # new logic for allow
            #   param: string - $LOG.info "your mom"
            #   param: exception - $LOG.error(e)
            #   non-exception param + block (param == progname, prefix message instead) - $LOG.warn("balls") { "dongs" }
            #
            # raise if:
            #   maybe_e is nil and no block provided
            #
            module_eval(<<-CODE, __FILE__, __LINE__+1)
                def #{meth}(maybe_e = nil, opts = { :depth => 5 }, &block)
                    raise "LOG##{meth}: no msg or block provided" if !block_given? && maybe_e.nil?

                    message = block_given? ? yield : ""
                    bt = nil

                    if maybe_e.kind_of?(Exception)
                         bt = maybe_e.inspect + " " + maybe_e.backtrace[0..opts[:depth]-1].inspect
                    elsif maybe_e
                        maybe_e += " >> " if block_given?
                        message.insert(0, maybe_e)
                    end

                    begin
                        monitor.capture("#{meth}", message)
                    rescue => exc
                        STDERR.puts "LOG##{meth}: monitor raised exception" + exc.inspect
                    end if monitor

                    # pass in a nil block to make sure the given block isn't being invoked again by Logger
                    super(message, &nil) unless message.blank?
                    super(bt, &nil)      unless bt.blank?
                end
            CODE
        end

        private

        def synchronize
            # This method is an odd hack for the specific case when the Log#configure
            # calls $LOG itself, which induces a double-lock from within the same thread.
            #
            # Background: configure() starts with a lock, and ensures an unlock; however
            # it calls $LOG.whatever whenever something is wrong (e.g. unknown logging
            # directive), and calls to info/error/etc themselves call synchronize, which
            # is equivalent to calling lock twice in a row, or calling synchronize twice
            # (one inside the other), or calling each of them once in a row, without ever
            # calling unlock.
            #
            # The reason we lock anything in the first place is because any >1 threads
            # that {Kernel,STDOUT}.puts at the same time will have their linefeed's merged
            # (only the last puts's LF is written, thus the individual puts's look
            # concatenated). (This seems like a dumb Ruby bug.) By putting a lock around
            # that, ruby is forced to complete each puts individually.  And wrapping
            # Log#configure with a lock just makes sense out of correctness and the
            # possibility that it might get called later after initialization.
            #
            # The reason Log#configure calls $LOG instead of straight puts's is because it
            # can possibly deliver to other places that don't care about locking (files,
            # sockets).  Imagine some configuration is fucked on 1 of 20 daemons, all of
            # whom are also logging to a central syslog server.  You might never know it
            # if you didn't try to deliver the message to all the possible targets.
            #
            # So, because of the catch-22 in Log#configure, we rescue the synchronize call
            # here with a straight call to block.call.  We could make it more specific to
            # only rescue ThreadError (which is what a double-lock/synchronize raises),
            # but is it necessary?  If the block itself threw an exception, it'll just get
            # thrown again and whatever outer rescue mechanism (if any) will still
            # trigger.
            #
            # NOTE: This library doesn't really use this for anything but straight
            # Kernel.warn.  The other "exception caught while evaluating logger block"
            # logic is unaffected by this.

            mutex.synchronize { yield } rescue yield
        end

    end

end

require 'sdn/log/formatter'

# No-op the stupid "hi this was created on X" header.
class Logger::LogDevice; def add_log_header(*); end; end

$LOG = ::SDN::Log.new

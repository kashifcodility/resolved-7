# Example: $SCHEDULER.at(Time.zone.now + 60.minutes, expire_task, [1234123])
#
module SDN::Scheduler
    BASE = File.dirname(__FILE__)

    module Strategy

        # Scheduling strategies return a number of seconds before the first
        # scheduled action (initial), and after that they get asked for a
        # subsequent period to wait each time the scheduled thing is run.

        class Jittered
            def initialize(config)
                @interval   = config[:interval]
                @range      = config[:jittered]
            end

            def initial
                initial = rand(@interval)
                $LOG.debug("First scheduled run in #{initial}s")
                return initial
            end

            def subsequent
                return jittered
            end

            def jittered
                jitter = (1.0 - (rand * 2.0)) * @interval * @range

                return (@interval + jitter).round
            end
        end
    end

    @@mutex    = Mutex.new
    @@thread   = nil
    @@schedule = { } # { id => { :time => x, :proc => &proc, :params => [] } }
    @@last_id  = 0

    cattr_accessor :interval, :delegate;

    const_def :DEFAULT_INTERVAL, 60.seconds # seconds
    self.interval = DEFAULT_INTERVAL

    extend Enumerable

    def self.schedule_recurring_job(job, interval)
        delay_type, delay =  self.parse_interval(interval)
        if delay_type == :at
            self.at(delay, job, [], true)
            $LOG.info "Schedule recurring job #{job} running at #{interval}, next run is at #{delay}"
        elsif delay_type == :in
            self.in(delay, job, [], true)
            $LOG.info "Schedule recurring job #{job} running on interval #{delay}s"
        else
            raise "unknown delay_type #{delay_type}"
        end
    end

    def self.boot!(async = true)
        shutdown!

        if $CONFIG[:scheduler].among?(0, false, "0", "false", "off", "disable", "disabled")
            $LOG.debug "scheduler: disabled"
            return
        end

        $LOG.debug "scheduler: booting"

        schedule = (@@delegate || Schedule.new)

        # Call Schedule class' configure method if it is defined
        schedule.send(:configure, self) if schedule.respond_to?(:configure)

        # Look at configuration to automatically populate recurring jobs
        if $CONFIG[:schedule]
            $CONFIG[:schedule].each do |job, interval|
                self.schedule_recurring_job(job, interval)
            end
        end

        @@thread = Thread.new { self.run! }
        @@thread.join unless async
    end

    def self.shutdown!
        if @@thread
            $LOG.debug "scheduler: shutting down"
            @@thread.kill.join
        end
    end

    def self.block!
        @@thread.join
    end

    # Interpret interval configuration
    def self.parse_interval(interval)
        # interval is an integer, that means the interval should be interval seconds from now
        return [:in, interval] if interval.is_a?(Fixnum)

        if interval.is_a?(String)
            # interval is a string, that specify particular time to run this
            next_time = Time.parse(interval)
            now = Time.zone.now
            while next_time.to_i < now.to_i
                next_time += 1.day
            end
            return [:at, next_time]
        end

        # if not a hash, interpret as strictly interval seconds
        unless interval.is_a?(Hash)
            raise "unknown interval type #{interval.class}"
        end

        # if no strategy is specified, assume it is strict
        return interval unless strategy = interval[:strategy]

        strategy_klass_name = strategy.to_s.capitalize

        unless strategy_klass = Strategy.const_get(strategy_klass_name)
            raise "Unknow scheduler strategy: #{strategy_klass_name}, check your app config"
        end

        real_strategy = strategy_klass.new(interval)
        return [:in, real_strategy.subsequent]
    end

    def self.run!
        loop do
            # Check if the proc is past-due (due_in is negative).  If not, record the
            # smallest interval from the entire schedule for which we'll sleep until we
            # run again.
            next_interval = @@interval

            @@mutex.synchronize do
                $LOG.debug "scheduler: scanning #{@@schedule.length}"
                now = Time.zone.now

                @@schedule.dup.each do |id, h|
                    overdue = now > h[:at]
                    unless overdue
                        next_interval = [next_interval, h[:at] - now].min
                        next
                    end

                    Thread.new do
                        begin
                            $SCHEDULER.remove(id) # remove ASAP, *then* do work
                            # you either
                            #   define a namespace'd Schedule static Class / Method or
                            #   specify a delegate
                            (@@delegate || Schedule.new).send(h[:proc], *h[:params])
                        rescue Exception => e
                            $LOG.error(e) { "scheduler: #{h[:proc]} (#{id}) raised exception" }
                        ensure
                            # Reschedule this job if it is a recurring job
                            if h[:recur] and $CONFIG[:schedule] and interval = $CONFIG[:schedule][h[:proc]]
                                self.schedule_recurring_job(h[:proc], interval)
                            end
                        end
                    end
                end
            end

            sleep(next_interval.ceil)
        end
    end

    def self.remove(id)
        @@mutex.synchronize do
            @@schedule.delete(id)
        end
    end

    def self.clear!
        @@mutex.synchronize { @@schedule.clear }
    end

    def self.asap(proc_sym, params = [])
        return self.in(0, proc_sym, params)
    end

    def self.in(timediff, proc_sym, params = [], recur = false)
        return self.at(Time.zone.now + timediff, proc_sym, params, recur)
    end

    def self.at(time, proc_sym, params = [], recur = false)
        id = @@last_id

        @@mutex.synchronize do
            id = next_id while @@schedule[id]

            @@schedule[id] = {
                :id     => id,
                :at     => time,
                :proc   => proc_sym,
                :params => params,
                :recur  => recur, # Indicate if this job is a recurring a job
            }
        end

        return id
    end

    def self.each
        @@mutex.synchronize do
            @@schedule.each_value { |todo| yield todo }
        end
    end

    private
    def self.next_id
        @@last_id += 1
    end
end

class Schedule; end

$SCHEDULER = ::SDN::Scheduler

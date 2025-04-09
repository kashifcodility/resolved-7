##
# Daemon Design
# Assumptions:
#   Each daemon running in their own process space also means daemon has exclusive access to $DB
#
# Schedule inner class
#   Public methods defined in this class will be registered as scheduled methods
#

require 'optparse'
require 'tilt'

require 'sdn/utils'
require 'sdn/log'
require 'sdn/config'
require 'sdn/scheduler'
require 'sdn/db'

require 'sdn/mcp/state'

module MCP
    class Daemon
        include State::InstanceMethods
        extend  State::ClassMethods

        attr_reader   :name, :working_directory
        attr_accessor :config, :amqp, :schedule

        def initialize
            # make sure we load the correct config even if we are started in mcp dir.
            @name              = self.class.to_s.split(/::/).last.underscore
            @config            = {}
            @working_directory = File.expand_path('../' + @name)

            $:.unshift File.expand_path(@working_directory)

            # Initialize the default name for any Daemon subclass Just in case
            # this daemon is started by script/run instead of launcher.
            $0 = @name.dup

            self
        end

        def init_db
            $DB.setup(self.working_directory)
        end

        def init_scheduler
            # Make sure this Schedule constants is defined by the daemon class,
            # not inherited from somewhere else.
            return unless schedule_class = self.class.const_get("Schedule") rescue nil
            return unless schedule_class.kind_of?(Class)

            $SCHEDULER.delegate = schedule = schedule_class.new

            methods  = schedule.public_methods(false)
            methods -= [ :initialize, :configure ]

            $LOG.warn "scheduler enabled without anything to schedule" if methods.empty?

            scheduler_interval = $SCHEDULER.interval

            methods.each do |schedule_handler|
                unless c = config[schedule_handler]
                    $LOG.debug "#{schedule_handler} not configured to run"
                    next
                end

                $LOG.debug "scheduling #{schedule_handler}"
                $SCHEDULER.in(1.second, schedule_handler)

                # Pick minimum proc interval as scheduler interval, otherwise
                # things will get missed.  Interval should either be the sole
                # config value, or key `interval` in a config hash (in the
                # YAML).
                proc_interval = c[:interval] rescue c
                scheduler_interval = proc_interval.to_i - 1 if proc_interval.to_i <= scheduler_interval
            end

            @schedule = schedule
            @schedule.class_eval { include SelfHelper }
            @schedule.daemon = self

            $SCHEDULER.interval = scheduler_interval
        end

        # Externally-callable method that will cause all the "init_*"s to fire,
        # but not induce any actual boot/run.
        def finalize!
            # Only finalize once on an instance.  Even if finalization fails, we'd
            # be in an indeterminate state and we shouldn't try again.
            return self if @finalized
            @finalized = true

            self.send(:init_before_hook) if self.respond_to?(:init_before_hook)

            # initialize all required components
            unless comps = self.class.components and comps.any?
                $LOG.warn "#{name} does not have any required components"
                return
            end

            comps.each do |comp|
                $LOG.debug "#{name}: #{comp} init"
                case comp
                when :DB            then init_db
                when :SCHEDULER     then init_scheduler
                end
            end

            return self
        end

        def prep_console_mode
            # initialize all required components
            unless comps = self.class.components and comps.any?
                $LOG.warn "#{name} does not have any required components"
                return
            end

            comps.each do |comp|
                $LOG.debug "#{name}: #{comp} init"
                case comp
                when :DB        then init_db
                when :SCHEDULER then next # does not init scheduler
                end
            end
        end

        def run(should_block = true)
            $CONFIG[:name] = @name
            $LOG.configure($CONFIG[:logging])

            finalize! unless @finalized

            self.send(:spawn_after_hook) if self.respond_to?(:spawn_after_hook)

            comps = self.class.components

            # Decide what to block on (otherwise run will return and we'll
            # exit!).  First scheduler.

            # If there is no Scheduler, our last-ditch is to invoke Daemon#main
            # and go with it.  If there's nothing, then we literally have
            # nothing to do.
            block_on   = [ :SCHEDULER ].find { |c| comps.include?(c) }
            block_on ||= :SELF if self.respond_to?(:main)

            if should_block and not block_on
                $LOG.fatal "nothing to do: no Scheduler or #{self.class}#main"
                raise
            end

            # Now boot up any background services.
            comps.each do |comp|
                case comp
                when :SCHEDULER     then $SCHEDULER.boot!
                end
            end

            $LOG.info "#{name}: running"

            return unless should_block

            # And block.
            case block_on
                when :SCHEDULER then $SCHEDULER.block!
                when :SELF      then self.main
            end
        end

        def run_non_block
            run(false)
        end

        # subclass daemons will check configuration in this method.  lacking any
        # specific knowledge of a config, we default to true.
        def valid_config?
            return true
        end

        # take either a config file name or a hash to be merged into current config
        def configure(settings = nil)
            settings ||= "config/app.yml"

            case settings
            when Hash
                if self.respond_to?(:configure_hook)
                    settings.each do |key, value|
                        if self.send(:configure_hook, key, value) == false
                            $LOG.warn "unable to set config #{key.inspect} => #{value.inspect}"
                        else
                            self.config[key] = value
                        end
                    end
                else
                    self.config.merge!(settings)
                end

            when String # Assume filename
                unless File.exists?(settings)
                    $LOG.error "#{settings} does not exist"
                    return false
                end

                return configure(::SDN::Config.load(settings))
            end

            return self
        end

        # Overload this if you want more specialized reconfig.
        def reconfigure(config_name = nil)
            $LOG.info "reconfiguring #{self.name} (#{Process.pid})"

            self.config = {}

            return configure(config_name)
        end

        # parse command line, use subclass daemon's parser if there is one
        def parse_cmdline_arguments
            ::OptionParser.new do |opts|
                # TBD.  None daemon-specific yet.
                self.send(:cmdline_arguments_hook, opts) if self.respond_to?(:cmdline_arguments_hook)
            end.parse!
        end

        # Module auto-included on Schedule nested class if defined, to help them
        # get to the Daemon instance ("self").
        #
        # We use ActiveSupport's delegation instead of re-including individual
        # helpers to aid mocking/testing scenarios: just point the daemon attr
        # to the stub/mock.
        #
        # FFR: contemplate doing away with this entirely and just "merging"
        # (include/extend) the Daemon instance onto the Schedule instance.  Then
        # the Daemon instance could be treated like the Controller, while the
        # Schedule methods are just the handlers invoking the controller
        # methods.
        module SelfHelper
            attr_accessor :daemon
            delegate :config, :render, :notify, :to => :daemon
        end

        # General helpers present for Daemon and Schedule class instance
        # methods alike.
        module Helpers
            # General helper for rendering templates, supporting (but not
            # limited to) sending outbound email.
            def render(template_erb, with_vars = {}, from_dir = self.working_directory / "views")
                filename = from_dir / template_erb
                template = Tilt.new(filename)
                return template.render(self, with_vars)
            rescue => e
                $LOG.error(e) { "failed to render template #{filename}" }
                raise e
            end
        end

        include Helpers

        module ClassMethods

            ##
            ## Daemon definition support methods
            ##

            attr_accessor :components

            def require_component(*comps)
                self.components = comps
            end

            alias :need :require_component
            alias :needs :require_component

            # Command-line argument processing for daemon subclasses.  Runs after
            # base class has a shot at the arguments.
            def cmdline_arguments(&block)
                define_method("cmdline_arguments_hook", &block)
            end

            # Configuration hook.  Block is passed key, value tuples (first-level)
            # iteratively from the YAML.
            def configure(&block)
                method_name = "configure_hook"
                define_method(method_name, &block)
            end

            # Register "before" Hooks.  Currently support: :init
            def before(hook_name, &hook_block)
                method_name = "#{hook_name}_before_hook"
                define_method(method_name, &hook_block)
            end

            # Register "after" hooks.  Currently support: :spawn
            def after(hook_name, &hook_block)
                method_name = "#{hook_name}_after_hook"
                define_method(method_name, &hook_block)
            end

            ##
            ## Utility methods
            ##

            def instantiate(daemon_name, daemon_path, daemon_config = nil, global_config = nil)
                daemon_file = daemon_path / "app" / daemon_name

                raise "unable to find #{daemon_name} in #{daemon_path}" unless
                    File.directory?(daemon_path) and # Hope this works with symlinks..
                    File.exists?(daemon_file + ".rb")

                $:.unshift File.expand_path(daemon_path)
                $:.unshift File.expand_path(daemon_path + '/app')

                # require daemon's dependneices file
                daemon_deps_file = daemon_path / "config" / "deps.rb"
                require daemon_deps_file

                # require daemon's code proper
                require daemon_file

                # Ensure we loaded something we expect.
                klass      = nil
                klass_name = daemon_name.camelcase
                begin
                    klass = Module::const_get(klass_name)
                rescue
                    msg = "unable to load #{klass_name} from file #{daemon_path}"
                    $LOG.fatal { msg }
                    raise msg
                end

                # Initialize and configure the daemon.
                daemon = klass.new
                unless daemon_config
                    daemon_config = "#{daemon_path}/config/app.yml"
                end

                daemon.configure(global_config) if global_config
                daemon.configure(daemon_config)

                # If the daemon has a command line parsing capability, let it parse
                # command line for additional configuration.
                daemon.parse_cmdline_arguments

                return daemon
            end

        end

        extend ClassMethods
    end
end

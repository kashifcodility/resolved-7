#
# Utility class to replace Rails bullshit logging.
#
# Included from SDN::Rails::Controller, which itself is (typically) attached to
# ApplicationController.
#
# NOTE: This module in its first incarnation is really single-use: it'll wipe
# the fuck out any existing subscriptions when included.  By default we assume
# we're an Application Controller.  I can't immediately intuit a better
# convention, so fuckit.  Caveat Emptor.
#

require 'active_support/log_subscriber'

module SDN
    module Rails
        module Logging
            extend self

            def included(klass)
                klass.class_eval do
                    # First we crowbar the default loggers out entirely, then
                    # attach ourselves as the sole subscriber left.
                    ActiveSupport::Notifications.notifier.instance_variable_set(:@string_subscribers, Hash.new { |h, k| h[k] = [] })

                    LogSubscriber.attach_to :action_view
                    LogSubscriber.attach_to :action_controller
                end
            end

            class LogSubscriber < ::ActiveSupport::LogSubscriber
                INTERNAL_PARAMS = %w(controller action format _method only_path)

                def start_processing(event)
                    payload = event.payload
                    params  = payload[:params].except(*INTERNAL_PARAMS)
                    format  = payload[:format] || :html

                    message  = ">> (%s) %s#%s" % [
                        format.to_s.upcase,
                        payload[:controller],
                        payload[:action],
                    ]
                    message << " (#{params.inspect})" unless params.empty?

                    $LOG.info message
                end

                def process_action(event)
                    payload   = event.payload
                    additions = ActionController::Base.log_process_action(payload) + [ "alloc: #{event.allocations}" ]
                    format    = payload[:format] || :html

                    message  = "<< (%s) %s#%s - %.0fms" % [
                        format.to_s.upcase,
                        payload[:controller],
                        payload[:action],
                        event.duration,
                    ]
                    message << " (#{additions.join(", ").downcase})" unless additions.blank?

                    $LOG.info message
                end

                def render_partial(event)
                    message =  "  << #{from_rails_root(event.payload[:identifier])}"
                    message << " (#{from_rails_root(event.payload[:layout])})" if event.payload[:layout]
                    message << " - #{event.duration.round(1)}ms (alloc: #{event.allocations})"
                    message << " #{cache_message(event.payload)}" unless event.payload[:cache_hit].nil?

                    $LOG.info message
                end

                def render_template(event)
                    message =  " << #{from_rails_root(event.payload[:identifier])}"
                    message << " (#{from_rails_root(event.payload[:layout])})" if event.payload[:layout]
                    message << " - #{event.duration.round(1)}ms (alloc: #{event.allocations})"

                    $LOG.info message
                end

                def render_collection(event)
                    identifier = event.payload[:identifier] || "templates"

                    message =  " << #{from_rails_root(identifier)}"
                    message << " #{render_count(event.payload)} - #{event.duration.round(1)}ms (alloc #{event.allocations})"

                    $LOG.info message
                end

                private

                const_def :EMPTY, ""
                const_def :VIEWS_PATTERN, /^app\/views\//

                def from_rails_root(string)
                    string = string.sub(rails_root, EMPTY) # string is frozen initially
                    string.sub!(VIEWS_PATTERN, EMPTY)
                    string
                end

                def rails_root
                    @root ||= "#{::Rails.root}/"
                end

                def render_count(payload)
                    if payload[:cache_hits]
                        "[#{payload[:cache_hits]} / #{payload[:count]} cache hits]"
                    else
                        "[#{payload[:count]} times]"
                    end
                end

                def cache_message(payload)
                    case payload[:cache_hit]
                    when :hit
                        "[cache hit]"
                    when :miss
                        "[cache miss]"
                    end
                end

            end
        end
    end
end

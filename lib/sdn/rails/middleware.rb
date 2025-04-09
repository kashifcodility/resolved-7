##
## Set the Rails middleware stack explicitly.
##
## Fuck you, Yehuda.  Fucken prick.

require 'sdn/log/rack'
require 'sdn/session_store'
require 'sdn/php/session'

module SDN
    module Rails
        module Middleware
            extend self

            def included(klass)
                # This is located in rails.git/railties/lib/rails/application.rb
                klass::DefaultMiddlewareStack.class_eval do
                    alias_method :orig_build_stack, :build_stack

                    def build_stack
                        # NOTE: We can modify Rails' stack here; nuke things
                        # from the stack, insert_{before,after}, etc.

                        orig_build_stack.tap do |middleware|
                            middleware.insert_after(
                                ::Rack::Sendfile,
                                ::SDN::Log::Rack, log: $LOG
                            )

                            session_key =  "_sdn" + ($CONFIG.env[0..2] rescue '')

                            middleware.insert_after(
                                ::ActionDispatch::Cookies,
                                ::SDN::SessionStore::Rack, {
                                    expire_after: 7.days,
                                    domain:       $CONFIG[:domain],
                                    key:          session_key,
                                })

                            middleware.insert_after(
                                ::SDN::SessionStore::Rack,
                                ::ActionDispatch::Flash
                            )

                            middleware.insert_after(
                                ActionDispatch::Flash,
                                ::SDN::PHP::Session::Rack, {
                                    path: "/tmp",
                                    sync_both: true,
                                    lock: true,
                                }
                            )
                        end
                    end
                end

                klass.class_eval do
                    # This is separate from the above because there are other
                    # initializers that potentially add their own middlewares which
                    # index off the position of presumed-untouched default Rails
                    # middlewares.  Doing the deletions as an initializer means
                    # we're very likely to run last (because everyone else's have
                    # been set by the time we run).

                    initializer :nuke_useless_middlewares do |_app|
                        _app.middleware.delete ::Rack::Runtime
                        _app.middleware.delete ::Rails::Rack::Logger

                        if $CONFIG.env == :production
                            _app.middleware.delete ::ActionDispatch::DebugExceptions
                            _app.middleware.delete ::ActionDispatch::ActionableExceptions
                        end
                    end
                end
            end
        end
    end
end

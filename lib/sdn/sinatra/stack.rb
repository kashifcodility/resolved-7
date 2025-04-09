require 'rack'
require 'rack/ssl'
require 'rack/contrib'

require 'rack/csrf'
require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/namespace'
require "sinatra/reloader"

require 'sdn/log/rack'
require 'sdn/session_store'

module SDN
    module Sinatra
        module Stack
            def self.registered(app)
                app.use ::SDN::Log::Rack, :log => $LOG
                app.use ::Rack::SSL unless $CONFIG[:require_ssl] == false || $CONFIG.env != :production
                app.use ::Rack::MethodOverride

                app.use ::SDN::SessionStore::Rack, {
                    expire_after: 7.days,
                    domain:       $CONFIG[:domain],
                    key:          "_sdn" + ($CONFIG.env[0..2] rescue '')
                }

                # Disabled on the assumption that we'll only use Sinatra for API
                # services; Can be added back in manually on the local server.
                #app.use ::Rack::Csrf, raise: true, key: '_csrf_token', skip_if: ->(req) { req.env['rack.test'] }

                app.register ::Sinatra::Flash
                app.register ::Sinatra::Namespace
                app.register ::Sinatra::Reloader

                helpers(app)   if app.respond_to?(:helpers)
                configure(app) if app.respond_to?(:enable)
                filters(app)   if app.respond_to?(:before)
            end

            def self.configure(app)
                app.enable :clean_trace, :static
                app.disable :logging, :raise_errors, :dump_errors, :raise_exceptions, :methodoverride

                app.set :port, '4269'

                app.mime_type :json, 'application/json'
            end

            def self.filters(app)
                # Set no-cache header on all calls to avoid IE and others from caching our
                # responses.  P3P responses: http://www.p3pwriter.com/LRN_111.asp
                app.before do
                    headers('Cache-Control' => 'no-cache',
                            'Expires'       => 'Wed, 01 Feb 1978 05:36:00 PST',
                            'P3P'           => 'CP="CAO PSA OUR"')
                end
            end

            def self.helpers(app)
                app.helpers Helpers
            end

            module Helpers
                def csrf_token()   ::Rack::Csrf.csrf_token(env)   end
                def csrf_tag()     ::Rack::Csrf.csrf_tag(env)     end
                def csrf_metatag() ::Rack::Csrf.csrf_metatag(env) end
                def csrf_header()  ::Rack::Csrf.csrf_header(env)  end

                def back
                    return request.referer || '/'
                end

                include ::Rack::Utils
                alias_method :h, :escape_html
            end

            extend self
        end
    end
end

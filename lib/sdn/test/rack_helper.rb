require 'rack/test'
require 'nokogiri'

module RackHelper

    class Browser

        include Rack::Test::Methods

        cattr_accessor :default_host
        cattr_accessor :no_session

        attr_accessor :location
        attr_accessor :session_id
        attr_accessor :session_key
        attr_accessor :host
        attr_accessor :default_params
        attr_accessor :xhr

        attr_reader   :options
        attr_reader   :cookies
        attr_reader   :no_session

        def initialize(session_data={}, options={})
            @host = options[:host] || self.class.default_host
            @no_session = self.class.no_session || options[:no_session]

            @options = options

            # Define "default" params that are always there.
            @default_params = {}

            return if self.no_session

            # Now do some session-handling BULLSHIT.
            #
            # Approach: each persona gets their own browser, and each
            # browser has its own cookie_name and cookie_value for handling
            # sessions.
            #
            # session_key = session's cookie_name
            # session_id  = session's cookie_value
            #
            # (1) determine cookie_name && cookie_value (we're initing)
            # (2) store the initial session data with session_id matching cookie_value
            # (3) manually set the session cookie with the cookie_value/session_id
            #
            # Then, the session middleware should find the cookie and load
            # the session data.  This will work the first time for certain.
            # Problems arise when (1) the persona.browser object is used
            # more than once during a session and (2) when the app stack
            # invocation requests the session be renewed (session_id is
            # changed inside the rack stack).

            unless self.host
                raise "You must set a default host or options[:host] to use the browser helper with sessions"
            end

            # (1) determine cookie_name && cookie_value
            self.session_id  = options[:name] || "test-user"
            self.session_key = options[:session_key] || "_ccsession"

            # (2) persist the initial session data into the session store
            self.session_data = session_data

            # NOTE: Welcome to Fucking CrazyTown.
            #
            # Because we are including Rack::Test::Methods instead of
            # deriving from Rack::Test::Session, we have less control over
            # how RTS (and within it, Rack::MockSession) is initialized.  We
            # also don't get other accessors, like for cookies.
            #
            # When RTS instantiates, it copies the "default_host" into
            # itself from the RMS.  Ideally we'd set it in the RMS and RTS
            # would pick it up when it initializes, but RTS is actually
            # initialized indirectly through "current_session" when you're
            # using Rack::Test::Methods.  So we don't have control over
            # setting RMS' ``default_host'' in advance, and thus have to set
            # it in both places.  Neither has write accessors, so we do it
            # directly.
            #
            # So, we bring a RTS into being by accessing "current_session",
            # then set the default host on both RTS and RMS.  This ensures
            # that any unqualified URLs that come through redirects, gets,
            # posts, etc will have access to the cookies that may be scoped
            # with the domain.

            rts = current_session
            rms = rts.instance_variable_get(:@rack_mock_session)

            rts.instance_variable_set(:@default_host, self.host)
            rms.instance_variable_set(:@default_host, self.host)

            # RTS Cookie methods are already delegated to RMS.  BUT, access
            # to the cookie_jar itself is not, so we have our own accessor
            # for it, and the CJ doesn't provide a method to clear itself,
            # so we add it to the CJ instance on the fly.

            rts.set_cookie("#{self.session_key}=#{self.session_id}")

            @cookies = rms.cookie_jar
            def @cookies.clear() @cookies.clear end

            # WARNING: Do not put additional code here - there's a return
            # above that assumes the remainder of the method is
            # session-related.
        end

        def app
            defined?(Rails) ? Rails.application : Server.new
        end

        def session_data
            data = ::SDN::SessionStore.get(self.session_id)
            return data
        end

        def session_data=(data)
            ::SDN::SessionStore.put(self.session_id, data)
            return data
        end

        def last_json
            return JSON.parse(last_response.body) rescue nil
        end
        alias :json :last_json

        def last_document
            Nokogiri::HTML(last_response.body)
        end
        alias :document :last_document


        # custom HTTP verb handlers

        %w[get put post delete].each do |http_method|
            class_eval(<<-ruby, __FILE__, __LINE__)
                def #{http_method}(uri, params={}, env={}, &block)
                    env = {"HTTP_REFERER" => self.location}.merge(env) if self.location
                    env = {"SERVER_NAME"  => self.host    }.merge(env) if self.host

                    if self.xhr
                        env = {
                            "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest",
                            "HTTP_ACCEPT"           => "application/json, text/javascript, */*",
                        }.merge(env)

                        #{case http_method
                          when 'delete', 'put' then
                              'env = {"X-HTTP-Method-Override" => method.to_s.upcase}.merge(env)'
                          end}
                    end

                    default = #{case http_method
                                when 'get' then '{}'
                                else '@default_params'
                                end}

                    real_params = default.merge(params)

                    result        = super(uri, real_params, env, &block)
                    new_location  = result['Location']
                    self.location = new_location if new_location

                    result
                rescue => e
                    $LOG.error "HTTP request handling broke"
                    raise e
                end
            ruby
        end
    end

    # A test browser instance
    def browser(options = {})
        @browser ||= RackHelper::Browser.new({}, {
                                                 :name => "unknown-#{auto_increment(:unknown_browser)}"
                                             }.merge(options))
    end

    # Allows us to re-use some Steps in web_steps ... see how it's used there We
    # have Steps for 'anonymous' browser requests, and ones for Persona-driven
    # browsers We want to re-use the anonymous logic for Personas, and if so, we
    # need to temporarily swap out the browser It's cheap, but effective
    def with_browser(browser, &block)
        raise "block required" unless block

        kept = @browser
        @browser = browser
        result = block.call
        @browser = kept

        return result
    end
end

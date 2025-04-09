module PersonaHelper
    class Persona

        # TODO: update for additional SDN user attributes, as necessary
        attr_accessor :user
        attr_accessor :first_name
        attr_accessor :last_name
        attr_accessor :email
        attr_accessor :username
        attr_accessor :mobile_username
        attr_accessor :apps

        def browser(reset=false)

            @browser = nil if reset
            return @browser if @browser

            # FIXME: We should probably make this a Mash.
            session_data             = {}
            session_data[:redirects] = [] # TODO: Do we need this?
            session_data[:current_user]  = self.user.id          if self.user

            session_key = '_sdn'
            session_key += $CONFIG[:cookie_suffix].to_s if $CONFIG[:cookie_suffix]

            @browser = RackHelper::Browser.new(session_data, {
                    :name        => "test-#{(self.first_name || 'persona').downcase}",
                    :session_key => session_key,
                })

        end

        # see support/pattern_definitions + :person_name
        def name
            return self.first_name
        end

        protected

        def initialize(options={})
            self.user            = options[:user]
            self.first_name      = options[:first_name]
            self.last_name       = options[:last_name]
            self.email           = options[:email]
            self.username        = options[:username]
            self.mobile_username = options[:mobile_username]
            self.apps            = {}
        end

    end
end

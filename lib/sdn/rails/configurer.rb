##
## Shared code for configuring Rails env the way we want it.
##

module SDN
    module Rails
        module Configurer
            extend self

            const_def :LOCALIZE_LOAD_PATH, 'config/locales/{**/*/**,}*.yml'

            def included(klass)
                klass.class_eval do
                    # 'config' is the Rails::Application::Configuration in scope
                    Configurer.konfigure(klass.config)
                end
            end

            ## Common options we want all Rails apps to have, regardless of ENV
            ## (vs. specifying on config/application.rb).  Still expected to be
            ## overridden as necessary by config/environments.
            ##
            ## Some options are taken from default initializers (because we
            ## basically don't use them).

            def konfigure(config)
                config.load_defaults 6.0

                # Configure L10N / I18N Support
                config.i18n.load_path += Dir[::Rails.root.join(LOCALIZE_LOAD_PATH)]
                config.i18n.fallbacks = true
                config.i18n.default_locale = :en

                config.encoding  = "utf-8"
                config.time_zone = 'Pacific Time (US & Canada)'
                ENV['TZ'] = 'Pacific Time (US & Canada)' # This is needed for DM

                config.log = $LOG
                config.logger = $LOG
                config.action_dispatch.logger = $LOG

                # Print deprecation notices to the Rails logger
                config.active_support.deprecation = :log

                # Only use best-standards-support built into browsers
                config.action_dispatch.best_standards_support = :builtin

                # Configure sensitive parameters which will be filtered from the log file.
                config.filter_parameters += [
                    :password, :mobile_password, :new_password, :password_redundant, :cc_number, :cc_verification,
                ]

                # Two ways to use Amazon SES -- 1 using the SES direct method,
                # and one through the Amazon SMTP relay.  We're going with SMTP
                # for now.

                fqdn = "www" + ($CONFIG[:domain] || ".sdninc.co")

                config.hosts << fqdn
                config.hosts << "localhost"
                config.hosts << "frontend"
                config.hosts << "admin"
                config.hosts << "payatclose.local.sdninc.co"

                # ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base, access_key_id: ENV['AMAZON_ACCESS_KEY'],
                #                                                              secret_access_key:# ENV['AMAZON_SECRET_KEY']
                # config.action_mailer.delivery_method = :ses
                if $AWS
                    config.action_mailer.delivery_method = :smtp
                    config.action_mailer.smtp_settings = {
                        address: "email-smtp.us-east-1.amazonaws.com",
                        port: 587,
                        user_name: $AWS.config[:ses][:username],
                        password: $AWS.config[:ses][:password],
                        authentication: :login,
                        enable_starttls_auto: true,
                    }

                    config.action_mailer.default_url_options = { host: fqdn }
                end

                # Disable Rails' session store in favor of our own added in
                # rails/middleware.rb.
                config.session_store(:disabled)

                # Configure asset pipeline
                config.assets.version        = '1.0' # changing supposedly expires all assets
                config.assets.enabled        = true
                config.assets.css_compressor = :sass
                config.assets.js_compressor  = :uglifier
                config.assets.log            = $LOG
                config.assets.logger         = $LOG

                config.assets.precompile += %w[ *.png *.jpg *.jpeg *.gif ]
                #config.assets.precompile += %w[ specific.css specific.js ]

                # Asset server (CDN, when we support it)
                #config.action_controller.asset_host = "http://assets.example.com"
                # :json, :marshal, or :hybrid
                config.action_dispatch.cookies_serializer = :json


                # Use ISO 8601 format for JSON serialized times and dates.
                #ActiveSupport.use_standard_json_time_format = true

                # Don't escape HTML entities in JSON, leave that for the
                # #json_escape helper.  if you're including raw json in an HTML
                # page.
                #ActiveSupport.escape_html_entities_in_json = false

                # Cause Rails fswatch_reloader to watch things in common/ruby
                # (under <app>/lib/sdn).  Unfortunately the reloader fucks
                # sockets up when used this way for some reason, so commenting
                # out for now and debugging later.

                #initializer "sdn.watch_common_files" do |app|
                #    app.reloaders << app.config.file_watcher.new([], {
                #        SDNROOT / "app/assets/javascripts" => ["jsx", "js"],
                #        SDNROOT / "lib/sdn" => ["rb"],
                #    }) {}
                #end

                config.action_dispatch.show_exceptions   = true
            end
        end
    end
end

require 'exception_notification/rails'



ExceptionNotification.configure do |config|
  # Ignore additional exception types.
  # ActiveRecord::RecordNotFound, AbstractController::ActionNotFound and ActionController::RoutingError are already added.
  # config.ignored_exceptions += %w{ActionView::TemplateError CustomError}

  # Adds a condition to decide when an exception must be ignored or not.
  # The ignore_if method can be invoked multiple times to add extra conditions.
  # config.ignore_if do |exception, options|
  #   not Rails.env.production?
  # end

  # Notifiers =================================================================

  # Email notifier sends notifications by email.
if Rails.env == "production"  

    config.add_notifier :email, {
        :email_prefix         => "[ERROR] ",
        :sender_address       => %{"notifier" <codilityw@gmail.com>},
        :exception_recipients => %w{codilityw@gmail.com}
        # ,
        # :delivery_method => :smtp,
        #   :smtp_settings => {
        #     :address => "smtp.gmail.com",
        #     :port => 587,
        #     :domain => 'gmail.com',
        #     :user_name => ENV.fetch("GMAIL_USERNAME", ""),
        #     :password => ENV.fetch("GMAIL_PASSWORD", ""),
        #     :authentication => "plain",
        #     :enable_starttls_auto => true
        #   }
    }
end
  # Campfire notifier sends notifications to your Campfire room. Requires 'tinder' gem.
  # config.add_notifier :campfire, {
  #   :subdomain => 'my_subdomain',
  #   :token => 'my_token',
  #   :room_name => 'my_room'
  # }

  # :sender_address => %{"notifier" <codilityw@gmail.com>},
  # :exception_recipients => %w{codilityw@gmail.com},

  # HipChat notifier sends notifications to your HipChat room. Requires 'hipchat' gem.
  # config.add_notifier :hipchat, {
  #   :api_token => 'my_token',
  #   :room_name => 'my_room'
  # }

  # Webhook notifier sends notifications over HTTP protocol. Requires 'httparty' gem.
  # config.add_notifier :webhook, {
  #   :url => 'http://example.com:5555/hubot/path',
  #   :http_method => :post
  # }

end

class TestMailer < ApplicationMailer

    def send_test(options={})
        @name    = options[:name]
        @message = options[:message]

        # HACK: template_name: necessary for when you're invoking from console
        # vs. inside a controller (then it just magically picks up the method
        # name from ActionController::Base.process).
        mail(to: ENV['USER'] + "@sdninc.co", subject: "TESTING !!! Amazon SES Email !!! TESTING",
             template_name: "send_test")
    end
end

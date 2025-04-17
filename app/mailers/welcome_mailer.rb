class WelcomeMailer < ApplicationMailer

    default from: 're|SOLVED <support@r-e-solved.com>'
    default to:   'support@r-e-solved.com'

    def send_welcome(user)
        @user = user
        subject = "Welcome to re|SOLVED"
        mail(to: user.email, cc: 'support@r-e-solved.com', subject: subject, template_name: "welcome_letter")
    end

end

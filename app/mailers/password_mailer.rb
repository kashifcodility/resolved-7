class PasswordMailer < ApplicationMailer

    default from: 're|SOLVED <support@r-e-solved.com>'
    default to:   'support@r-e-solved.com'

    def send_reset_password(user, code:)
        @user = user
        @reset_code = code

        subject = "Password Recovery for re|SOLVED"
        mail(to: user.email, subject: subject, template_name: "reset_password")
    end

    def send_password_changed(user, changed_at:)
        @user = user
        @when = changed_at

        subject = "Password Changed for re|SOLVED"
        mail(to: user.email, cc: 'support@r-e-solved.com', subject: subject, template_name: "password_changed")
    end
end

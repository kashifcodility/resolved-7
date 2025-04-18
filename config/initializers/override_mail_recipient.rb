# Prevents emails in non-prod environments from being sent to users
# Stolen from: https://stackoverflow.com/a/10870805
# unless Rails.env.production?

#     $LOG.info "MAILER: Overriding all mail recipients to: #{$CONFIG[:emails_to] || 'support@r-e-solved.com'}"

#     class OverrideMailRecipient
#         def self.delivering_email(mail)
#             mail.to = $CONFIG[:emails_to] || 'support@r-e-solved.com'
#         end
#     end
#     ActionMailer::Base.register_interceptor(OverrideMailRecipient)
# end
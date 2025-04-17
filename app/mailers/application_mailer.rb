class ApplicationMailer < ActionMailer::Base
    default from: 're|SOLVED <support@r-e-solved.com>'
    default to: 'support@r-e-solved.com'

    layout 'mailer'

    include ActionView::Helpers::TextHelper
end

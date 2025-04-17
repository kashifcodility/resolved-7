class ContactMailer < ApplicationMailer

    default from: 're|SOLVED <support@r-e-solved.com>'
    default to:   'support@r-e-solved.com'

    def send_info_request(email:, first_name:nil, phone:nil, location:nil)
        @message = "This person wants more information about adding inventory to the system."
        @info = OpenStruct.new(email: email, first_name: first_name, phone: phone)
        @subject = "Add Inventory Request"

        to = location == "25" ? 'moi-phx@sdninc.net' : 'moi@sdninc.net'

        mail(to: to, cc: 'support@r-e-solved.com' , subject: @subject, template_name: "info_request")
    end

end

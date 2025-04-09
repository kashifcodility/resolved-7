class InfoController < ApplicationController

    def index
        @main_heading = get_cms_fields('about', 'main_heading')
        @our_mission = get_cms_fields('about', 'our_mission')
        @our_vision = get_cms_fields('about', 'our_vision')
        @heading_1 = get_cms_fields('about', 'heading_1')
        @heading_2 = get_cms_fields('about', 'heading_2')
        @heading_3 = get_cms_fields('about', 'heading_3')
        @description_1 = get_cms_fields('about', 'description_1')
        @description_2 = get_cms_fields('about', 'description_2')
        @description_3 = get_cms_fields('about', 'description_3')
        @description_header_1 = get_cms_fields('about', 'description_header_1')
        @description_header_2 = get_cms_fields('about', 'description_header_2')
        @signature = get_cms_fields('about', 'signature')
        @header_1_image = get_cms_fields('about', 'header_1_image')
        @header_2_image = get_cms_fields('about', 'header_2_image')
        render
    end

    # Send request info emailp
    def send_request_info_email
        email = params[:email]
        location = params[:location]
        to = location == "25" ? 'moi-phx@sdninc.net' : 'moi@sdninc.net'

        return json_error('Invalid email address. Please try again.') unless email =~ URI::MailTo::EMAIL_REGEXP
        return json_error('Invalid location selected. Please try again.') unless location.to_i.among?(Site.active.pluck(:id))

        email = ContactMailer.new.send_info_request(email: email, first_name: params[:first_name], phone: params[:phone], location: location).deliver
        return json_error('Error sending email. Please try again.') if email.errors.any?


        return json_success("Thank you. Your request has been submitted. Expect to hear from us soon. Add #{to} to your safe-sender list or check your spam box to ensure we connect.")
    end

    def contact
        render
    end

    def faq
        render
    end

    def privacy
        render
    end

    def services
        render
    end

    def covid
        render
    end

    def moi
        render
    end

    private
    def get_cms_fields(page, title)
        Cms.first(page: page, title: title)
    end

end

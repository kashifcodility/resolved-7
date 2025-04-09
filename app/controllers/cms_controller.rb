class CmsController < ApplicationController
    def index
        render
    end

    def homepage
        @main_heading               = get_cms_fields('homepage', 'main_heading')
        @main_description           = get_cms_fields('homepage', 'main_description')
        @heading_1                  = get_cms_fields('homepage', 'heading_1')
        @heading_2                  = get_cms_fields('homepage', 'heading_2')
        @description_1              = get_cms_fields('homepage', 'description_1')
        @description_2              = get_cms_fields('homepage', 'description_2')
        @feedback_main              = get_cms_fields('homepage', 'feedback_main')
        @feedback_heading_1         = get_cms_fields('homepage', 'feedback_heading_1')
        @feedback_heading_2         = get_cms_fields('homepage', 'feedback_heading_2')
        @feedback_heading_3         = get_cms_fields('homepage', 'feedback_heading_3')
        @feedback_description_1     = get_cms_fields('homepage', 'feedback_description_1')
        @feedback_description_2     = get_cms_fields('homepage', 'feedback_description_2')
        @feedback_description_3     = get_cms_fields('homepage', 'feedback_description_3')
        render
    end

    def about
        @main_heading  = get_cms_fields('about', 'main_heading')
        @our_mission   = get_cms_fields('about', 'our_mission')
        @our_vision    = get_cms_fields('about', 'our_vision')
        @heading_1     = get_cms_fields('about', 'heading_1')
        @heading_2     = get_cms_fields('about', 'heading_2')
        @heading_3     = get_cms_fields('about', 'heading_3')
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

    def update_about
        errors = []
        if params[:file]
            errors << 'Photo too large. Max size is 1 MB.' unless params[:file].size <= 1.megabyte

            unless errors.any?
                new_filename = "#{current_user.username}_#{Time.zone.now.to_i}_#{params[:file].original_filename}"
                s3_bucket = 'sdn-content'

                # Perform the upload
                upload_success = $AWS.s3.upload(
                    params[:file].tempfile,
                    bucket: s3_bucket,
                    as: new_filename,
                )

                if upload_success
                    # Generate the file URL
                    file_url = $AWS.s3.public_url_for(new_filename, bucket: s3_bucket)
                    @url = file_url
                else
                    errors << 'Error uploading photo.'
                end

                puts 'received your file. now move to the next step'
            end
        end

        @title = params[:title]
        update_description('about',@title, @url)
        redirect_to cms_about_path
    end

    def update_homepage
        @title = params[:title]
        update_description('homepage',@title)
        redirect_to cms_homepage_path
    end

    private
    def update_description(page, title, url=nil)
        Cms.first(page: page, title: @title).update(description: params["#{@title}"], file_url: url)
    end

    def get_cms_fields(page, title)
        Cms.first(page: page, title: title)
    end
end

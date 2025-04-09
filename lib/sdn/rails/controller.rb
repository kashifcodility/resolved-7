##
## Common code for root Controller (ApplicationController) that will fix any
## Rails application logging + set standard before_filters (aka set_p3p_header).
##

require 'sdn/rails/logging'

module SDN
module Rails
    module Controller
        extend self

        def included(klass)
            klass.class_eval do
                before_action :set_p3p_header

                # ::SDN::Rails::Logging nukes Rails' default garbage and
                # replaces it with our own lovely unicorn farts.
                include ::SDN::Rails::Logging

                # CSRF protection
                #   includes PUT and DELETE verbs
                #   see:  ActionController::RequestForgeryProtection
                #   see:  ActionView::Helpers::CsrfHelper
                protect_from_forgery with: :null_session unless $CONFIG.env == :development

                # Set mailer domain info
                if $AWS
                    def default_url_options
                        ::Rails.application.config.action_mailer.default_url_options.merge!({
                            host: request.host_with_port,
                            protocol: request.protocol,
                        })
                    end
                end
            end
        end

        ##
        ## Helper filters
        ##

        # allow cross-domain / third-party cookie tolerance in IE browsers
        #   http://stackoverflow.com/questions/6241626/facebook-ie-and-p3p
        #   http://forum.developers.facebook.com/viewtopic.php?id=452
        def set_p3p_header
            response.headers["P3P"] = %q{CP="CAO PSA OUR"}
        end

        # ensures that this request came from an XHR (XmlHttpRequest, eg. AJAX)
        def ensure_xhr_request
            return nil if request.xml_http_request?
            return render(:status => 402, :text => 'Not Authorized')
        end

        def ignore_notification_of_exception?(request, exception)
            return true if
                request.path_info.match(/\.swf$/) or # previously included .gif
                request.path_info.match(/google-analytics\.com|jqModal\.js/)
        end
    end
end
end

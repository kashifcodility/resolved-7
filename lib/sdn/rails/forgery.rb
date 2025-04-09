##
## extended support for CSRF / forgery prorection
##
## patterned after
##   ActionController::RequestForgeryProtection
##   ActionView::Helpers::CsrfHelper
##
## FYI:  constants that Rails 3.2 uses internally
##   session key containing token = :_csrf_token
##   HTTP Header set with token   = 'X-CSRF-Token'
##   <input name="" /> for token  = (set by #request_forgery_protection_token, defaults to 'authenticity_token')

module SDN
module Rails
module Forgery
    module Helpers
        # an <input type="hidden" />
        def csrf_input_tag
            return tag('input',
                :type => 'hidden',
                :name => request_forgery_protection_token,
                :value => form_authenticity_token
            ).html_safe
        end

        # an Hash to be received as part of a request params
        def csrf_params_hash
            return { request_forgery_protection_token => form_authenticity_token }
        end
    end
end
end
end

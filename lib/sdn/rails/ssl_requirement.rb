# Copyright (c) 2005 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module SslRequirement

    extend ActiveSupport::Concern

    mattr_writer :ssl_host, :ssl_port, :non_ssl_host, :non_ssl_port, :disable_ssl_check
    mattr_accessor :redirect_status

    included do
        class_attribute :ssl_required_actions
        class_attribute :ssl_allowed_actions

        before_filter :ensure_proper_protocol
    end

    module ClassMethods
        # Specifies that the named actions requires an SSL connection to be
        # performed (which is enforced by ensure_proper_protocol).
        def ssl_required(*actions)
            self.ssl_required_actions ||= []
            self.ssl_required_actions += actions
        end

        # To allow SSL for any action pass :all as action like this:
        # ssl_allowed :all
        def ssl_allowed(*actions)
            self.ssl_allowed_actions ||= []
            self.ssl_allowed_actions += actions
        end
    end

    protected

    def ssl_required?
        (self.class.ssl_required_actions || []).include?(action_name.to_sym)
    end

    def ssl_allowed?
        allowed_actions = self.class.ssl_allowed_actions || []
        allowed_actions == [:all] || allowed_actions.include?(action_name.to_sym)
    end


    private

    def ensure_proper_protocol
        if ssl_required? && !request.ssl?
            redirect_to "https://" + request.host + request.request_uri
            flash.keep
            return false
        end

        # Make SSL permissive by default (don't ever downgrade).
        #      elsif request.ssl? && !ssl_required?
        #        redirect_to "http://" + request.host + request.request_uri
        #        flash.keep
        #        return false
        #      end

        # Unless we say otherwise, the protocol is proper.
        return true
    end
end

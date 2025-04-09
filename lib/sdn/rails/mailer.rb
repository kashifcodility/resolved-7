##
## Common code for root mailer (ApplicationMailer).
##

require 'sdn/rails/logging'

module SDN
module Rails
    module Mailer
        extend self

        def included(klass)
            klass.class_eval do
                # no-op for now..
            end
        end
    end
end
end

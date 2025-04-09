# Sprockets by default has a configurable logger when run from Rake task
# automation, but NOT when those Rake tasks were generated from Rails automation
# (which we need so Sprockets picks up all its configuration info from
# Rails.application.config).  So we have to monkey patch in our $LOG after the
# manifest initializes.  Works great! :-P

#require 'sprockets'

module ::FixSprocketsLogging
    def initialize(*args)
        super(*args)
        @environment.logger = $LOG
    end
end

class ::Sprockets::Manifest
    prepend ::FixSprocketsLogging
end

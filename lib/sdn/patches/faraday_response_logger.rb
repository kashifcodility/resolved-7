require 'faraday'
require 'faraday/response'
require 'faraday/response/logger'


module ::EnsureFaradayUsesOurLogger
    def initialize(app, logger = nil, options = {})
        super(app, $LOG, options)
    end
end


module ::Faraday
    class Response::Logger
        prepend ::EnsureFaradayUsesOurLogger
    end
end

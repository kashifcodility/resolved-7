require 'sdn/log'

class SDN::Log
    class Rack

        def initialize(app, opts = {})
            raise ArgumentError.new("#{self.class.to_s} needs a Logger target specified") unless opts[:log]
            @app    = app
            @logger = opts[:log]
        end

        def call(env)
            request = ::Rack::Request.new(env)

            # ActionDispatch::Static actually overwrites PATH_INFO with an
            # URL-escaped version.  Can't figure out why, and shit goes sideways
            # if you disable the AD::Static middleware, so we dup the string to
            # fix the optics on the way out.
            #
            # https://github.com/rails/rails/commit/d07b2f3e295031b4a2b6a3f8c80d7e92a78329c2
            path_info = request.path_info.dup

            @logger.info %{[%s] >> "%s %s%s" (%s)} %
                [ request.ip,
                  request.request_method,
                  path_info,
                  request.query_string.blank? ? "" : "?"+request.query_string,
                  (request.scheme.upcase rescue 'HTTP')
                ]

            start = Time.now
            status, header, body = @app.call(env)
            stop  = Time.now

            length = 0
            body.each { |p| length += p.bytesize }

            @logger.info %{[%s] << "%s %s%s" %d %sb %0.4fs} %
                [ request.ip,
                  request.request_method,
                  path_info,
                  request.query_string.blank? ? "" : "?"+request.query_string,
                  status.to_s[0..3],
                  (length.zero? ? "-" : length.to_s),
                  stop - start ]

            [status, header, body]
        end

    end

    Apache = Rack
end


# Rack adapter to integrate PHP sessions with Ruby's.
# Author: Jordan Ritter <jpr5@sdninc.co>
#
# Works based on the assumption that only one session is being accessed at a
# time (not great but the best option ATM).  PHP session is treated as the
# single source of truth for PHP-based session variables; we load them into our
# own, but only save them back to the PHP session (vs. our own).
#
# Conventions
#
#   When sync_both is enabled, ruby session variables are written to the PHP
#   session with the prefix "ruby_".
#
#   When PHP session variables are imported into the Ruby session, they are
#   prefixed with "php_".  Any alterations to "php_*":values will be written
#   back to the PHP session without the "php_" prefix at the end of the request.
#
# Config
#
#   session_path:  Location on filesystem where PHP is storing the sessions
#   lock_sessions: Use file-locking on PHP session to prevent races
#   sync_both:     Load and Save both ruby & PHP values in both session stores
#                  Otheriwse, PHP->Ruby, Ruby(PHP)->PHP only
#
# Logic
#
#   On app entry (load)
#
#     if PHPSESSION cookie
#       load PHP session from config.session_path
#         if DNE
#           NUKE COOKIE (if it's not there, the PHP server doesn't see it either)
#           return
#         if config.lock_sessions # prevent PHP server race condition
#           flock(file, File::LOCK_EX)
#       deserialize php session
#         PHP.deserialize
#       rename/transform variables
#         add "php_" prefix unless "ruby_"
#         remove "ruby_" prefix if "ruby_"
#       collect variables to php_dessionize
#         if config.sync_both
#           use everything
#         else
#           use only non-"ruby_"-prefixed items
#       put variables into session[]
#
#   On app exit (save)
#
#     if PHPSESSION cookie
#       get variables from session[]
#       collect variables to php_sessionize
#         if config.sync_both
#           use everything
#         else
#           use only "php_"-prefixed values
#       rename/transform variables
#         add "ruby_" prefix unless "php_"
#         remove "php_" prefix if "php_"
#       serialize PHP session
#         PHP.serialize
#       save PHP session to config.session_path
#         if config.lock_sessions
#           flock(file, File::LOCK_UN)
#       nuke php_ variables from our session so they're not saved into our own
#         (PHP remains single source of truth)

module ::SDN::PHP
    module Session
        class Rack

            def initialize(app, opts = {})
                @app       = app

                @logger    = opts[:log] || $LOG
                @name      = opts[:name] || "PHPSESSID"
                @path      = opts[:path] || $CONFIG[:php][:session][:path] rescue nil
                @sync_both = opts[:sync_both] || $CONFIG[:php][:session][:sync_both] rescue nil
                @lock      = opts[:lock] || $CONFIG[:php][:session][:lock] rescue nil

                unless @logger && @path && @sync_both && @lock
                    raise ArgumentError.new("#{self.class} missing necessary config opts")
                end
            end

            def call(env)
                # before / app entry
                req = ::Rack::Request.new(env)

                return @app.call(env) unless php_cookie = req.cookies[@name]

                filename = @path / "sess_" + php_cookie

                unless session_file = File.new(filename, "r+") rescue nil
                    status, header, body = @app.call(env)
                    res = ::Rack::Response::Raw.new(status, header)
                    res.delete_cookie(@name)
                    return [res.status, res.headers, body]
                end

                # NOTE: This doesn't appear to work on OSX...sigh :-(
                session_file.flock(file, File::LOCK_EX) if @lock_sessions

                session_raw = session_file.read rescue ''

                return @app.call(env) if session_raw.empty?

                #$LOG.debug "loaded: #{session_raw}"

                session_deserial = ::SDN::PHP.deserialize(session_raw)
                session_filtered = session_deserial.map do |k, v|
                    k = k.dup
                    if k =~ /^ruby_/
                        k.sub!(/^ruby_/, "")
                    else
                        k.insert(0, "php_")
                    end

                    [k, v]
                end.to_h

                session_final = session_filtered.select do |k, _|
                    @sync_both || !(k =~ /^ruby_/)
                end

                # Add to session
                session_final.each { |k,v| env['rack.session'][k] = v }

                status, header, body = @app.call(env)

                res = ::Rack::Response::Raw.new(status, header)

                # after / app exit

                session_vars = env['rack.session'].to_hash.select do |k, _|
                    @sync_both || k =~ /php_/
                end

                session_filtered = session_vars.map do |k, v|
                    k = k.dup
                    if (k =~ /^php_/)
                        k.sub!(/^php_/, '')
                    else
                        k.insert(0, "ruby_")
                    end
                    [k, v]
                end.to_h

                session_serial = ::SDN::PHP.serialize_session(session_filtered.except('ruby_flash'))

                session_file.truncate(0)
                session_file.rewind
                session_file.write(session_serial)
                session_file.close

                # Nuke php_ vars out of our session so PHP remains single source
                # of truth for PHP session values.
                env['rack.session'].keys.grep(/^php_/).each do |k,_|
                    env['rack.session'].delete(k)
                end

                [res.status, res.headers, body]
            rescue => e
                $LOG.error(e)
                raise e
            ensure
                session_file.flock(file, File::LOCK_UN) if session_file rescue false
            end

        end
    end
end

require 'sdn/php/serialize'

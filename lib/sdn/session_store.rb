# SDN Session Store Middleware (Rack-based)
#
# History
#
#   - needed session store that works consistently across different frameworks
#   - needed session store to work with DataMapper + MySQL
#   - needed to (de)serialize objects in specific apps
#   - needed support for mixed-scheme session access (http vs. https)
#   - needed support for run-time cookie-domain resolution
#   - needed framework-specific Flash (hash) support
#   - needed a variant of session-by-parameter support (SWFUploader)
#
# How Flash Works (Rails' FlashHash and Rack's rack-flash3)
#
#   Both make available a session-based helper called "flash", whose purpose is
#   generally to be a temporary store for information for the *next* sequential
#   request.  So, given "flash[:foo] = bar":
#
#   (1) flash stores { :foo => bar } internally
#       - assignment marks key as "keep"
#   (2) session gets serialized after request completes
#       - flash is serialized with only keys marked "keep"
#       - all (previous) others discarded
#   (3) new request comes in, session is deserialized
#   (4) flash is deserialized, *then #sweep is called*
#       - #sweep marks any existing keys "don't keep"
#   (5) flash[] is used however needed
#   (6) session gets serialized after request completes
#       - flash is serialized with only keys marked "keep"
#       - only assignment of new values effects a "keep"
#       - thus the previously stored keys were marked "don't keep" by #sweep
#       - serialization of flash omits those keys (they disappear)

#
# SessionStore is the singleton that knows how to persist shit.
# SessionStore::Rack is the middleware that implements {get,set,destroy}_session semantics
# SessionStore::BSON manages (de)serialization into a format that can be stuffed into the DB.
#

require 'rack/session/abstract/id'

module SDN
    class SessionStore

        include Singleton

        class << self
            delegate :collection, :count,           :to => 'self.instance'
            delegate :get, :put, :delete, :exists?, :to => 'self.instance'
            delegate :configure,                    :to => 'self.instance'
        end

        const_def :DEFAULT_OPTIONS, {
            :collection => 'sessions',
        }

        def initialize
            @config = DEFAULT_OPTIONS.dup
        end

        # collection is a conceptual holdover from Mongo support.  We'll just
        # keep it here as a pointer to the "session class".
        def configure(opts={})
            @config.deep_merge!(opts).each do |k, v|
                case k
                when :collection then @config[:collection] = v.to_s.constantize
                else $LOG.warn "session_store: unknown option #{k}=#{v}"
                end
            end
        end

        def collection
            @collection ||= @config[:collection].classify.constantize
        end

        def count
            collection.count
        end

        def put(sid, session_data)
            synced = false

            $DB.transaction do
                session = collection.first(:session_id => sid) ||
                          collection.new(:session_id => sid)

                session.data = session_data

                synced = session.dirty? || session.new? ? session.save : true
            end

            $LOG.warn("session not synced") unless synced
            return synced
        end

        def get(sid)
            session = exists?(sid) and session.data or nil
        end

        def delete(sid)
            collection.first(:session_id => sid).destroy
        rescue => e
            $LOG.error(e) { "couldn't destroy session [#{sid}]" }
        end

        def exists?(sid)
            collection.first(:session_id => sid)
        end

        class Rack < ::Rack::Session::Abstract::ID

            attr_reader :mutex

            const_def :DEFAULT_OPTIONS, ::Rack::Session::Abstract::ID::DEFAULT_OPTIONS.merge({
                :expire_after => 7.days,
            })

            # use SDN::SessionStore::Rack, :collection => "session", ..
            def initialize(app, options={})
                super
                @mutex = Mutex.new
                @store = SessionStore.instance
            end

            def generate_sid
                loop do
                    sid = ::SDN::Utils::RefCode.generate(@sid_length)
                    break sid unless @store.exists?(sid)
                end
            end

            def get_session(env, sid)
                with_lock(env, [nil, {}]) do
                    unless sid and session = @store.get(sid)
                        sid, session = generate_sid, {}
                        @store.put(sid, session)
                    end
                    [sid, session]
                end
            end

            def set_session(env, session_id, new_session, options)
                with_lock(env, false) do
                    @store.put(session_id, new_session)
                    session_id
                end
            end

            def set_cookie(env, headers, cookie)
                cookie[:domain] &&= cookie[:domain].call(env) if cookie[:domain].is_a?(Proc)
                super
            end

            def destroy_session(env, session_id, options)
                with_lock(env) do
                    @store.delete(session_id)
                    next if options[:drop]
                    options[:fixate] && session_id || generate_sid
                end
            end

            def with_lock(env, default=nil)
                @mutex.lock if env['rack.multithread']
                yield
            rescue => e
                $LOG.error(e) { "SDN SessionStore failed" }
                default
            ensure
                @mutex.unlock if @mutex.locked?
            end

        end

        # NOTE: #(de)serialize is usually handed a BSON::OrderedHash, which
        # itself happily accepts both symbol and string keys:
        #
        #  { :foo => :bar, "foo" =>"bar" }
        #
        # Two problems happen with serializing session to JSON/BSON:
        #
        # (1) we haven't been entirely consistent about using string vs symbol
        #     keys WRT the session and flash hashes.
        #
        # (2) in the cases where we use symbol keys, serialization converts them
        #     to strings, so when deserialized, they are string keys and callers
        #     expecting symbol keys don't work.
        #
        # For our internal purposes, we just #to_mash the thing and it will
        # "just work".  For external purposes, where a given Thing might contain
        # differing types of keys and/or instances of classes known only to the
        # local application, we revert back to the opaque approach of
        # Marshal.dump/load + Base64.{en,de}code64.

        module BSON
            extend self

            const_def :SERIALIZABLE_TYPES, [
                ::TrueClass, ::FalseClass, ::Integer, ::String, ::Float, ::Integer, ::Symbol,
                ::Hash, ::Array, ::ActiveSupport::HashWithIndifferentAccess
            ]

            def bson_serialize(object)
                return nil unless object

                object = object.to_mash

                if defined?(::ActionDispatch::Flash::FlashHash) and
                   flash = object[:flash] and
                   flash.kind_of?(::ActionDispatch::Flash::FlashHash)

                    # We want to serialize the FlashHash but it's likelt that
                    # this flash object is a shared reference within some other
                    # Rails code.  To avoid any ill effects, we make our own
                    # copy for the sole purpose of sessionization, then call
                    # sweep to nuke keys that aren't supposed to be kept across
                    # a request.

                    new_flash = flash.dup
                    new_flash.sweep

                    # Then convert the FlashHash back into a straight hash,
                    # serialize in binary form, abd b64 encode the result.  This
                    # makes the flash key opaque, but fuckit, it works.
                    #
                    # TODO: Consider that we don't put stupid shit into the
                    # flash hash anymore and shouldn't worry about B64'ing..

                    object[:flash] = ::Base64.encode64(::Marshal.dump(::Hash[new_flash]))
                end

                return BSON.valid_object?(object) ? object : nil
            end

            def bson_deserialize(_object)
                return nil unless _object

                object = _object.to_mash

                # NOTE: to_mash is not recursive, but it should be OK.
                object['__FLASH__'] &&= object['__FLASH__'].to_mash

                if defined?(::ActionDispatch::Flash::FlashHash) and
                        flash = object[:flash] and
                        !flash.kind_of?(::ActionDispatch::Flash::FlashHash)

                    object[:flash] = new_flash = ::ActionDispatch::Flash::FlashHash.new

                    # WARNING: Do not change/optimize the .each call for the
                    # key/value assignments to an update() or replace() -
                    # FlashHash hooks update/replace, which interferes with what
                    # we're doing.

                    flash = ::Marshal.load(::Base64.decode64(flash)) rescue flash
                    flash.each { |k,v| new_flash[k] = v }
                end

                object
            end

            def valid_type?(value)
                unless known = value.class.among?(*SERIALIZABLE_TYPES)
                    $LOG.error "#{value.inspect} not serializable into BSON (class #{value.class.name})"
                end

                return known
            end

            def valid_object?(object)
                return true if object.nil?
                return false unless valid_type?(object)

                if object.is_a?(::Array)
                    object.each do |value|
                        return false unless valid_object?(value)
                    end
                end

                if object.is_a?(::Hash) or object.is_a?(::ActiveSupport::HashWithIndifferentAccess)
                    object.each do |key, value|
                        if key.to_s.include?(".")
                            $LOG.error "#{object.inspect} with key #{key} can't be serialized"
                            return false
                        end

                        unless valid_object?(value)
                            $LOG.error "key #{key} does not contain a serializable type"
                            return false
                        end
                    end
                end

                return true
            end
        end
    end
end

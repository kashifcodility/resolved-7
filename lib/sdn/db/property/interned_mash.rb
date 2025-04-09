require 'digest/sha1'

module SDN::DB::Property
    class InternedMash < ::DataMapper::Property::String
        const_def :DIGEST_LENGTH, 40

        # Note that options which refer to models *must* support
        # getting strings, since there's no guarantee of order between
        # when various models load.
        accept_options :storage_model, :digest_field, :content_field
        length DIGEST_LENGTH

        # No point in validating value's length, which is saved in another model anyway
        auto_validation false

        def custom?
            true
        end

        #   :storage_model  = the model class that actually stores the content
        #     can be a either DM model or Mongoid model
        #   :digest_field   = the field name that contains the SHA1 of the content
        #     will be used for looking up the actual content
        #   :content_field  = the field name that contains the content
        #     should return a Hash like object
        def initialize(model, name, options = {})
            @storage_model  = options[:storage_model]
            @digest_field   = options[:digest_field]
            @content_field  = options[:content_field]

            raise "Must set :storage_model, :digest_field and :content_field" unless @storage_model and @digest_field and @content_field
            return super
        end

        def primitive?(value)
            # no need for conversion if it's already of the specified Class
            # stay the hell away from nil
            result = (value.nil? || value.is_a?(::Hash))
            return result
        end

        def valid?(value, negated = false)
            # super is ignored because it is checking the value retried from the accessor of this field,
            # which returns a Hash object rather the digest
            return value.nil? || is_sha?(dump(value))
        end

        # raw_value is whatever that is loaded from DB
        def load(raw_value)
            return nil if raw_value.nil?

            # If it is not a String, then it is not a SHA nor JSON string, then it probably is the wrong thing being loaded...
            return raw_value unless raw_value.is_a?(::String)

            unless is_sha?(raw_value)
                # Not a SHA, probably the legacy case, where the data loaded from DB is a JSON
                return ::JSON.load(raw_value)
            end

            # raw_value is a SHA
            # load the content
            storage = $DB.first(storage_model, @digest_field => raw_value)
            content = storage.send(@content_field)
            content = JSON.parse(content).to_mash if content.is_a?(::String)
            return content
        end

        def dump(value)
            # there's no reason to typecast these
            return value if value.nil?

            if value.is_a?(::String)
                raise ArgumentError, "Should not assgin SHA value #{value} directly"
            end

            unless value.is_a?(::Hash)
                raise ArgumentError, "Should only assign Hash"
            end

            digest = self.class.generate(value.to_json)
            storage = $DB.first(storage_model, @digest_field => digest)

            unless storage
                $DB.create_model(storage_model, {
                    @digest_field   => digest,
                    @content_field  => value,
                })
            end

            return digest
        end

        def typecast_to_primitive(value)
            load(value.to_s)
        end

        def storage_model
            return @storage_model unless @storage_model.is_a?(::String)
            @storage_model = @storage_model.constantize
            return @storage_model
        end

        protected

        def is_sha?(content)
            return false if content.nil?
            return false unless content.length == DIGEST_LENGTH
            return false unless content.match(/^[0-9a-f]*$/)
            return true
        end

        def self.generate(content)
            return Digest::SHA1.hexdigest(content)
        end
    end
end


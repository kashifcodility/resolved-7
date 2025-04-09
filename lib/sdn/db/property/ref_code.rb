require 'digest/sha1'

module SDN::DB::Property
    class RefCode < ::DataMapper::Property::String
        required     true
        unique_index true
        default      proc { |_, prop| prop.class.generate(prop.length) }

        # Setting :length and :format before passing on the initialization chain
        # will cause dm-validations (if present) to auto-add validations for us.
        def initialize(model, name, options = {})
            options[:length] = options[:length]..options[:length] unless options[:length].is_a?(Range)
            options[:format] = /^[0-9a-z]*$/ if defined? ::DataMapper::Validations
            model.send(:include, ::SDN::Mixins::RetrySave)
            super
        end

        def primitive?(value)
            return value.kind_of?(::String)
        end

        # DM "core" validation (non dm-validations).  Validates both format and
        # length, but in the absence of dm-validations, the result will be #save
        # failure without actually populating #errors (confusing, but better
        # than saving bad data).
        def valid?(value, negated = false)
            return super && value.match(/^[0-9a-z]{#{range.min},#{range.max}}$/)
        end

        def range
            return @length.is_a?(Range) ? @length : @length..@length
        end

        protected

        def self.generate(size)
            # Must take the last <size> digits
            # The first <size> digits of SHA1 digest is not really very random...
            #return Digest::SHA1.hexdigest(rand.to_s).to_i(16).to_s(36)[(-size)..-1]
            return ::SDN::Utils::RefCode.generate(size)
        end
    end
end

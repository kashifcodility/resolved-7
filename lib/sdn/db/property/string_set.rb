require 'set'

module SDN::DB::Property
    class StringSet < ::DataMapper::Property::String
        accept_options :values
        attr_reader :values

        def initialize(model, name, options = {})
            values = self.class.values
            @values = values.to_set
            super
        end

        def load(value)
            return nil if value.nil? or !value.split(",").to_set.subset?(@values)
            return value.split(',').to_set
        end

        def dump(value)
            case value
            when ::NilClass then value
            when ::Array, ::Set then value.to_set.subset?(@values) ? value.to_a.join(",") : ["Bad Values"]
            when ::String then value
            else nil
            end
        end

        def typecast_to_primitive(value)
            case value
            when ::NilClass then value
            when ::Symbol then [value.to_s].to_set
            when ::String then [value].to_set
            when ::Array, ::Set then value.map { |e| e.to_s }.to_set
            else
                $LOG.warn "DB: can't typecast [#{value}] for #{self.name}(#{self.class.name})"
                nil
            end
        end
        alias_method :typecast, :typecast_to_primitive

        def valid?(value, negated = false)
            return super && value.subset?(@values)
        end

        def custom?() true end

        # Hack to enable StringEnum[...] specification; need def[] to return a
        # new class instance each time.
        class << self
            attr_accessor :generated_classes
        end
        self.generated_classes = {}

        def self.[](*values)
            if klass = generated_classes[values.flatten]
                klass
            else
                klass = ::Class.new(self)
                klass.values(values)
                generated_classes[values.flatten] = klass
                klass
            end
        end

    end # class StringSet
end # module SDN::DB::Property

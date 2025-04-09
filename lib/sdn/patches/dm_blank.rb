module DataMapper
    module Ext
        class << self
            alias :orig_blank? :blank?
        end

        def self.blank?(value)
            return value.blank? if value.respond_to?(:blank?)
            return orig_blank?(value)
        end
    end
end

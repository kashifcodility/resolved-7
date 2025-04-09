require 'active_support'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/hash'

module SDN
    module Utils
        module Hash
            extend self

            def included(klass)
                klass.class_eval do
                    include InstanceMethods
                end
            end

            module InstanceMethods
                def arrayify_integer_keysets
                    if !empty? and keys.all? {|key| key.to_s =~ /^\d+$/}
                        keys.sort_by{|k|k.to_i}.map do |key|
                            value = self[key]
                            value = value.arrayify_integer_keysets if value.is_a?(Hash)
                            value
                        end
                    else
                        return inject(self.class.new) do |hash, (key, value)|
                            value = value.arrayify_integer_keysets if value.is_a?(Hash)
                            hash.merge(key => value)
                        end
                    end
                end

                def deep_clone
                    ::Hash[
                        map do |v|
                            v.map do |x|
                                x.respond_to?(:deep_clone) ? x.deep_clone : (x.respond_to?(:dup) ? (x.dup rescue x) : x)
                            end
                        end
                    ]
                end

                # So activesupport expects deep_merge and deep_merge! when using the with_options
                # option merger library like we do in routes.  So I've commented out the ones that
                # break routing and put in these versions ripped out of
                # ActiveSupport::CoreExtensions::Hash::DeepMerge and this way everything remains
                # compatible.
                #
                # # Nice utility functions to properly merge arbitrary-depth hashes together.  When
                # # non-hash values merge, other overrides self.  (There is another kind of merge we
                # # might want which resolves collisions into an array, but that isn't the typical
                # # behaviour we want for arbitrary-depth overriding merges).
                #
                # def deep_merge!(other)
                #     other.each_pair do |k,v|
                #         if self[k].is_a?(Hash) and other[k].is_a?(Hash)
                #             self[k].deep_merge!(other[k])
                #         else
                #             self[k] = other[k]
                #         end
                #     end
                # end
                #
                # def deep_merge(other)
                #     deep_clone.deep_merge!(other)
                # end

                # Returns a new hash with +self+ and +other_hash+ merged recursively.
                def deep_merge_and_concat_arrays(other_hash)
                    self.merge(other_hash) do |key, oldval, newval|
                        next newval unless newval.kind_of?(oldval.class)

                        newval = case oldval
                            when Hash  then oldval.deep_merge(newval)
                            when Array then oldval.concat(newval)
                            else            newval
                        end

                        next newval
                    end
                end
                alias :deep_merge :deep_merge_and_concat_arrays

                # Returns a new hash with +self+ and +other_hash+ merged recursively.
                # Modifies the receiver in place.
                def deep_merge!(other_hash)
                    replace(deep_merge(other_hash))
                end

                def explode(delimiter)
                    new = self.class.new
                    each do |key, value|
                        case value
                        when ::Hash then
                            value.explode(delimiter).each do |sub_key, sub_value|
                                new[[key, sub_key].join(delimiter)] = sub_value
                            end
                        else
                            new[key] = value
                        end
                    end
                    new
                end

                def hashify_array_values
                    hash = self.class.new
                    each do |key, value|
                        hash[key] =
                            case value
                            when ::Hash then
                                # nested Hash
                                value.hashify_array_values

                            when ::Array then
                                hash_value = self.class.new
                                value.each_with_index do |item, index|
                                    # nested Array of Hashes
                                    item = item.hashify_array_values if item.is_a?(::Hash)
                                    hash_value[index + 1] = item
                                end
                                hash_value

                            else value
                            end
                    end
                    hash
                end

                def deep_stringify_keys
                    hash = self.stringify_keys
                    hash.each do |key, value|
                        case value
                        when Hash  then hash[key] = value.stringify_keys
                        when Array then hash[key] = value.collect {|v| (v.is_a?(Hash) ? v.stringify_keys : v) }
                        end
                    end
                    return hash
                end

                # result is an ActiveSupport::OrderedHash
                def deep_stringify_and_sort(&sort_by)
                    result = ActiveSupport::OrderedHash.new
                    hash = self.stringify_keys
                    hash.stringify_keys.keys.sort(&sort_by).each do |key|
                        case value = hash[key]
                        when Hash  then result[key] = value.deep_stringify_and_sort(&sort_by)
                        when Array then result[key] = value.collect {|v| (v.is_a?(Hash) ? v.deep_stringify_and_sort(&sort_by) : v) }
                        else            result[key] = value
                        end
                    end
                    return result
                end

                # collapses a Hash of arbitrary depth using iterations of
                #   1. stringify_keys
                #   2. hashify_array_values
                #   2. explode
                # this has a lot of value in cuke-land
                # Array indexes will be 1-based
                # what does it mean??
                #   { :array => [ 'x', 2 ] }                    becomes  { "array.1" => "x", "array.2" => 2 }
                #   { :array => [ { :value => 'x' } ] }         becomes  { "array.1.value" => "x" }
                #   { :array => [ { :value => [ 'x', 2 ] } ] }  becomes  { "array.1.value.1" => "x", "array.1.value.2" => 2 }
                #   ... and so on
                # if it looks like the inverse of .deep_stringify_and_implode, it kinda is
                def deep_stringify_and_explode(delimiter = '.')
                    hash = self.stringify_keys
                    while hash.any? {|(key, value)| value.is_a?(Array) || value.is_a?(Hash) }
                        hash = hash.hashify_array_values.explode(delimiter).stringify_keys
                    end
                    return hash
                end

                def implode(delimiter)
                    new = self.class.new
                    each do |key, value|
                        base = new
                        new_keys = key.split(delimiter)
                        while new_keys.length > 1
                            new_key = new_keys.shift
                            base = base[new_key] ||= {}
                        end
                        base[new_keys.first] = value
                    end
                    new
                end

                # expands a Hash into arbitrary depth using iterations of
                #   1. stringify_keys
                #   2. implode
                # this has a lot of value in cuke-land
                # what does it mean??
                #   { "array.1" => "x", "array.2" => 2 }                  becomes  { :array => [ 'x', 2 ] }
                #   { "array.1.value" => "x" }                            becomes  { :array => [ { :value => 'x' } ] }
                #   { "array.1.value.1" => "x", "array.1.value.2" => 2 }  becomes  { :array => [ { :value => [ 'x', 2 ] } ] }
                #   ... and so on
                # if it looks like the inverse of .deep_stringify_and_explode, it kinda is
                def deep_stringify_and_implode(delimiter = '.')
                    hash = self.stringify_keys.implode(delimiter)
                    hash.each do |key, value|
                        next unless value.is_a?(Hash)
                        hash[key] = value.deep_stringify_and_implode(delimiter)
                    end
                    return hash
                end

                def literalize
                    self.class[ self.map{|k,v| [ k, (v.respond_to?(:literalize) ? v.literalize : v) ] } ]
                end

                # Return a hash where all keys are symbols (Recursive)
                def symbolize
                    return self if symbolized?
                    inject({}) do |options, (key, value)|
                        key_sym = key.to_sym rescue key
                        raise RuntimeError, "duplicate key detected" if options.has_key?(key_sym)
                        options[key_sym || key] = (value.respond_to?(:symbolize) ? value.symbolize : value)
                        next options
                    end
                end

                # Is this hash already symbolized? (Recursive)
                def symbolized?
                    all? do |key,value|
                        next false unless key == (key.to_sym rescue nil)
                        next value.respond_to?(:symbolized?) ? value.symbolized? : true
                    end
                end

                # Modify this hash in place, converting all keys to symbols (Recursive)
                def symbolize!
                    return replace(symbolize)
                end

                # Translate single-value list values (at the top level) to scalars
                #
                # This is most useful when processing Borat answers, which,
                # even for single-valued controls, always return arrays.
                def scalarize_single_valued_arrays()
                    return self.map do |k,v|
                        v = case
                            when v.is_a?(::Array) && v.length == 1 then
                                v.first
                            when v.is_a?(::Hash) then
                                v.scalarize_single_valued_arrays
                            else
                                v
                            end
                        [k,v]
                    end.to_mash
                end

                def to_query_string
                    query = self.map do |name, values|
                        Array(values).map do |value|
                            "#{CGI.escape(name.to_s)}=#{CGI.escape(value.to_s)}"
                        end
                    end.flatten.join("&")

                    query.insert(0, "?") if query.present?
                    return query
                end

                # Hash#only + remove the keys from the original hash.  This is
                # basically the inverse of what slice! does (FKN H8 Rails).
                def only!(*keys)
                    ret = only(*keys)
                    replace(except(*keys))
                    return ret
                end
            end

        end
    end
end

class Hash
    include SDN::Utils::Hash

    alias :only :slice

    # alias old Extlib method to ActiveSupport equivalent
    alias :to_mash :with_indifferent_access
end

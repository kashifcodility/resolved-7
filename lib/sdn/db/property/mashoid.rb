module SDN
module Field
    module MongoWorkarounds
        def escape_mongo_string(s)
            return s.gsub("%", "%25").gsub(".", "%2E").gsub("$", "%24")
        end

        def unescape_mongo_string(s)
            return s.gsub("%2E", ".").gsub("%24", "$").gsub("%25", "%")
        end

        def escape_keys(hash)
            unless hash.is_a?(Hash)
                return hash
            end

            escaped_hash = {}
            hash.each do |key, value|
                value = escape_keys(value) if value.is_a?(Hash)
                escaped_hash[escape_mongo_string(key.to_s)] = value
            end

            return escaped_hash
        end

        def unescape_keys(hash)
            unless hash.is_a?(Hash)
                return hash
            end

            unescaped_hash = {}
            hash.each do |key, value|
                value = unescape_keys(value) if value.is_a?(Hash)
                unescaped_hash[unescape_mongo_string(key.to_s)] = value
            end

            return unescaped_hash
        end
    end

    # A Mash Mongoid Field
    class Mashoid
        include ::Mongoid::Fields::Serializable
        include MongoWorkarounds

        def deserialize(object)
            return nil if object.nil?
            return unescape_keys(object).to_mash
        end

        def serialize(object)
            return nil if object.nil?
            return escape_keys(::Hash[object])
        end
    end
end
end


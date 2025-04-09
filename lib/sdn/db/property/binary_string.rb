module SDN
module Field
    # A string of any (not just UTF-8) encoding. Does *not* coerce,
    # but will leave a UTF-8 string alone so you can still read it
    # with MongoHub. Others get binary encoded (i.e. base64'ed by
    # the Mongo driver).
    #
    # Can also be used with non-string data; e.g., an image will also
    # work; OTOH I'm certain there are some binary types where this
    # deserialization will get you something you didn't expect
    #
    # Enhancements that might be good:
    #   Allow field options to support Binary types other than just :generic
    #   (there are three others)
    class BinaryString
        include ::Mongoid::Fields::Serializable

        def deserialize(object)
            return nil if object.nil?
            return object.to_s
        end

        def serialize(object)
            return nil if object.nil?
            if object.respond_to?(:encoding) and object.encoding == Encoding::UTF_8
                return object
            end

            # Don't want this to actually change the object I'm called with
            # (it's bad enough that we don't preserve encoding across
            # persistence), so have to dup before encoding.
            if object.respond_to?(:encode) and
               utf8 = object.dup.force_encoding(Encoding::UTF_8) and
               utf8.valid_encoding?

                return utf8
            end

            return BSON::Binary.new(object)
        rescue EncodingError => e
            return BSON::Binary.new(object)
        end
    end
end
end


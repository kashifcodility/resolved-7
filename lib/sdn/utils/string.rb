module SDN
    module Utils
        module String

            # Useful path-related "foo" / "bar".
            def /(o)
                return File.join(self, o.to_s)
            end

            # Returns a Hash by parsing the string as JSON.
            def from_json
                return JSON.parse(self)
            end if ::Object.const_defined?(:JSON)

            # Given the Hash.from_xml code does not realize values as anything other than
            # strings, arrays, and hashes, we have to apply some conversions to values if
            # we want things like booleans, nils, integers and decimals.
            def literalize
                value = self
                case value
                when /^-?\d+$/        then value.to_i
                when /^-?\d+\.\d+$/   then value.to_f
                when 'false', 'FALSE' then false
                when 'true', 'TRUE', 'yes', 'on', 'y' then true
                when 'nil'            then nil
                else
                    if (value.index(':') == 0) && (value.size > 1)
                        value[1..-1].to_sym
                    else
                        value
                    end
                end
            end

            # Helpful conditional pluralization extension for string
            # Would have been better if pluralize had support for
            # count and multiple words with capitals etc but they do
            # not, so this method goes right here.
            # 'person'.quantify(0)      # => 'people'
            # 'person'.quantify(1)      # => 'person'
            # 'person'.quantify(2)      # => 'people'
            # 'person'.quantify(1,true) # => '1 person'
            # 'person'.quantify(2,true) # => '2 people'
            def quantify(number=nil, prepend=false)
                word = self
                word = word.pluralize unless number == 1
                word = [number, word].join(' ') if prepend
                word
            end

            # In 1.9, String is no longer Enumerable directly.  We've used
            # String#any? to achieve a more readable semantic inverse of
            # String#empty?.  Without assuming ActiveSupport is present (which
            # would give us String#present?), we add #any? back in and avoid
            # having to run through our entire codebase to correct.
            def any?
                !empty?
            end unless ::String.respond_to?(:any?)

            # There is also a summarize application helper used
            # in frontend, but this is handy anywhere you need
            # to limit an output string. Say in a notification
            # from some library component.
            def summarize(length = 100, elipsis = true)
                return truncate(length)
            end

            # Introduce concept of "downcode": a transcode that effectively
            # ignores any of the incompatibilities to the target encoding.
            def downcode(encoding)
                return self.encode(encoding, :invalid => :replace, :undef => :replace, :replace => '')
            end

            def downcode!(encoding)
                return replace(self.downcode(encoding))
            end


            def utf8_strip
                return self.utf8_lstrip.utf8_rstrip
            end

            def utf8_lstrip
                return self.gsub(/^[[:space:]]+/, '')
            end

            def utf8_rstrip
                return self.gsub(/[[:space:]]+$/, '')
            end
        end
    end
end

class String
    include SDN::Utils::String
end

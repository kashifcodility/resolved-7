require 'dm-core'
require 'sdn/utils/object'

# Super K-Rad Awesome module to apply Rails' "filter_params" concept to Model
# attribute's as well.  Only affects #inspect, actual values are intact.

module ::KeepSomeAttributesPrivate
    const_def :RANDO_PRIVACY, [ "NOPE", "NUH UH", "NONE OF YOUR BEEZWAX", "NOTHING TO SEE HERE",
                                "LOOK AWAY", "STOP PEEPING", "DON'T BE PERVY", "GFY", "F OFF" ]

    def inspect
        ret = super

        return ret unless filter_params = Rails.configuration.filter_parameters rescue nil

        filter_params.each do |p|
            filter = RANDO_PRIVACY.shuffle.first
            ret.gsub!(/(@#{p}=)[^"< ]+/, "\\1#{filter}")
            ret.gsub!(/(@#{p}=["<])[^"<]+([">])/, "\\1#{filter}\\2")
            ret.gsub!(/(@#{p}=#<)[^>]+([>])/, "\\1#{filter}\\2")
        end

        return ret
    end

    extend self
end

::DataMapper::Model.append_inclusions(::KeepSomeAttributesPrivate)

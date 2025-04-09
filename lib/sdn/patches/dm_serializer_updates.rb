require 'dm-core'

module ::FixDMSerializersForLatestRuby

    def to_hash
        self.attributes
    end

    def to_yaml
        self.attributes.to_yaml
    end

end

::DataMapper::Model.append_inclusions(::FixDMSerializersForLatestRuby)

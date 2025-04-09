class Address
    include DataMapper::Resource

    storage_names[:default] = "addresses"

    property :id, Serial

    # NOTE: sql definition is missing default (OK, just different)
    property :active, String, length: 10, allow_nil: true, default: "Active"

    property :name, String, length: 40, allow_nil: true
    def first_name()  name.split(/\s/).first rescue name    end
    def last_name()   name.split(/\s/)[1..].join rescue ''  end
    
    property :company, String, length: 40, allow_nil: true
    property :address1, String, length: 100, allow_nil: true
    property :address2, String, length: 100, allow_nil: true
    property :city, String, length: 40, allow_nil: true

    property :state, String, length: 2, allow_nil: true

    property :zipcode, String, length: 10, allow_nil: true

    property :country_id, Integer, default: 1 # Default US
    belongs_to :country

    property :phone, String, length: 15, allow_nil: true
    property :mobile_phone, String, length: 15, allow_nil: true

    # TODO: confirm this saves/stores proper precision
    property :latitude, Float, allow_nil: true
    property :longitude, Float, allow_nil: true

    # FIXME: WTF are these?
    property :table_name, String, length: 40, lazy: true
    property :table_id, Integer, lazy: true

    def full_address
        return "%s%s %s, %s. %s" % [ address1, (address2 ? " #{address2}" : ''), city, state, zipcode ]
    end

    def formatted_phone
        clean_phone = phone&.delete('^0-9')
        if clean_phone&.size == 10
            phone = "(%i) %i-%i" % [ clean_phone[-10..-8].to_i, clean_phone[-7..-5].to_i, clean_phone[-4..].to_i ] rescue phone
        end 
        return phone
    end
    
end

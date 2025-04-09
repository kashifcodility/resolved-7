class Commission
    include ::DataMapper::Resource

    storage_names[:default] = 'commission'

    property :id, Serial

    belongs_to :user, child_key: [ :customer_id ]
    belongs_to :product
    
    property :base_price, Float
    property :start_date, Date
    property :end_date, Date
    property :days, Integer, max: 255
    property :commission, Float

    belongs_to :site, child_key: [ :location_id ]
    
    property :cycle, Date
    
    belongs_to :payment

    property :type, StringEnum['RENT','SALE'], default: 'RENT' 

    property :timestamp, DateTime
end

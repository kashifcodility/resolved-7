# class Commission
#     include ::DataMapper::Resource

#     storage_names[:default] = 'commission'

#     property :id, Serial

#     belongs_to :user, child_key: [ :customer_id ]
#     belongs_to :product
    
#     property :base_price, Float
#     property :start_date, Date
#     property :end_date, Date
#     property :days, Integer, max: 255
#     property :commission, Float

#     belongs_to :site, child_key: [ :location_id ]
    
#     property :cycle, Date
    
#     belongs_to :payment

#     property :type, StringEnum['RENT','SALE'], default: 'RENT' 

#     property :timestamp, DateTime
# end

class Commission < ApplicationRecord
    self.table_name = 'commission'

    belongs_to :user, foreign_key: 'customer_id'
    belongs_to :product
    belongs_to :site, foreign_key: 'location_id'
    belongs_to :payment

    enum type: { RENT: 'RENT', SALE: 'SALE' }

    validates :days, numericality: { only_integer: true, less_than_or_equal_to: 255 }

    # Assuming you have the following columns in your commissions table:
    # id, base_price, start_date, end_date, days, commission, cycle, type, timestamp
end

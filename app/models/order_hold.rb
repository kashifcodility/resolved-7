# class OrderHold
#     include DataMapper::Resource

#     storage_names[:default] = 'orders_on_hold'
    
#     property :id, Serial

#     belongs_to :order, allow_nil: false

#     property :on_hold, StringEnum['CHARGE', 'HOLD'], default: 'HOLD'

#     property :created_by, Integer, allow_nil: false
#     property :updated_by, Integer, allow_nil: false
#     timestamps :at


class OrderHold < ApplicationRecord
    # Associations
    belongs_to :order
  
    # Validations (optional, adjust as needed)
    validates :order_id, presence: true
    validates :on_hold, inclusion: { in: ['CHARGE', 'HOLD'] }
    validates :created_by, :updated_by, presence: true
    
    def self.on_hold
        all(on_hold: 'HOLD')
    end
end

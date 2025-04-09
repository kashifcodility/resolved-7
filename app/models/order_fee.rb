# class OrderFee
#     include DataMapper::Resource

#     storage_names[:default] = "order_fees"

#     property :id, Serial

#     property :order_id, Integer, index: true
#     belongs_to :order

#     property :payment_id, Integer, index: true
#     belongs_to :payment

#     belongs_to :user

#     # FIXME: these should be DECIMAL, not FLOAT!  Rounding problems are
#     # inevitable now..
#     property :charges, Float
#     property :destage, Float
#     property :shipping, Float
#     property :waiver, Float
#     property :tax, Float
#     property :amount, Float

#     property :products, Json, lazy: false, default: []

#     property :updated_at, DateTime, field: 'date'

class OrderFee < ApplicationRecord
    # Associations
    belongs_to :order
    belongs_to :payment
    belongs_to :user
  
    # Validations (optional, adjust as needed)
    validates :order_id, presence: true
    validates :payment_id, presence: true
    validates :user_id, presence: true
    validates :charges, :destage, :shipping, :waiver, :tax, :amount, numericality: true, allow_nil: true
  

    # Gets the total for a given product ID on a singular order fee record
    def product_total(product_id)
        return 0.to_d unless products.any?
        return products.select{ |p| p[0] == product_id }.sum{ |p| p[1].to_d }
    end

end

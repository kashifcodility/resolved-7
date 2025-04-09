# class IhsOrder
#     include DataMapper::Resource

#     storage_names[:default] = "ihs_orders"
    
#     property :id, Serial
#     belongs_to :rental_order, model: 'Order', child_key: [ :rental_order_id ]
#     property :tax_authority_id, Integer, allow_nil: true
#     belongs_to :tax_authority, required: false
#     property :transaction_id, Integer, allow_nil: true
#     belongs_to :transaction, required: false
#     property :payment_id, Integer, allow_nil: true
#     belongs_to :payment, model: 'PaymentLog', child_key: [ :payment_id ], required: false

#     property :lines, Json, default: {}, lazy: false
#     property :billing_details, Json, default: {}, lazy: false
#     property :delivery_details, Json, default: {}, lazy: false
    
#     property :subtotal, Decimal, precision: 13, scale: 4, allow_nil: false
#     property :tax_total, Decimal, precision: 13, scale: 4, allow_nil: false
#     property :delivery_total, Decimal, precision: 13, scale: 4, allow_nil: false
#     property :total, Decimal, precision: 13, scale: 4, allow_nil: false

#     timestamps :at

class IhsOrder < ApplicationRecord
    # Associations
    belongs_to :rental_order, class_name: 'Order', foreign_key: 'rental_order_id', optional: true
    belongs_to :tax_authority, optional: true
    belongs_to :transaction, optional: true
    belongs_to :payment, class_name: 'PaymentLog', foreign_key: 'payment_id', optional: true
  
    # JSON columns
    # ActiveRecord supports storing JSON data types in databases that support it (e.g., PostgreSQL, MySQL 5.7+)
    store :lines, :json, default: {}
    store :billing_details, :json, default: {}
    store :delivery_details, :json, default: {}
  
    # Validations (optional, based on your business logic)
    validates :subtotal, :tax_total, :delivery_total, :total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  


    def self.sold_product_ids(rental_order_id: nil)
        f = { fields: [ :lines ], }
        f[:rental_order_id] = rental_order_id if rental_order_id
        
        sold_products = IhsOrder.all(f)
        return sold_products.any? ? sold_products.pluck(:lines).flatten.uniq.pluck('id') : []        
    end

    def self.already_sold_product?(product_id, rental_order_id: nil)
        return product_id.to_i.among?(self.sold_product_ids(rental_order_id: rental_order_id))
    end
end

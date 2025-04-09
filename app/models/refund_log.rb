# class RefundLog
#     include DataMapper::Resource

#     storage_names[:default] = "refund_log"
    
#     property :id, Serial

#     property :payment_id, Integer, index: true
#     belongs_to :payment

#     property :line_id, Integer, index: true

#     property :amount, Float

#     property :type,  StringEnum['NULL','DEFAULT','Order','Membership','Fees','Others']

#     property :refunded_by, Integer

#     property :description, String, length: 250
    
#     property :status,  StringEnum['NULL','DEFAULT','OK','REJECTED']

#     property :timestamp, DateTime, field: 'timestamp'
 
#     property :refund_payment_id, Integer, index: true
#     belongs_to :payment

#     property :reason, String, length: 100

#     property :reason_description, String, length: 300

# end



class RefundLog < ApplicationRecord
    # Set the table name explicitly if different from the default
    self.table_name = 'refund_log'  # If the table name is different from the default pluralized form
  
    # Associations
    belongs_to :payment
    belongs_to :refund_payment, class_name: 'Payment', foreign_key: 'refund_payment_id'
  
    # Validations
    validates :payment_id, presence: true
    validates :line_id, presence: true
    validates :amount, presence: true, numericality: true
    validates :type, inclusion: { in: ['NULL', 'DEFAULT', 'Order', 'Membership', 'Fees', 'Others'] }
    validates :refunded_by, presence: true
    validates :description, length: { maximum: 250 }
    validates :status, inclusion: { in: ['NULL', 'DEFAULT', 'OK', 'REJECTED'] }
    validates :reason, length: { maximum: 100 }
    validates :reason_description, length: { maximum: 300 }
  
end  
  
  
  
    # Additional methods can be added as needed for business logic
end
  

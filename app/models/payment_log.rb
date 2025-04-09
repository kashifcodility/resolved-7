# class PaymentLog
#     include DataMapper::Resource

#     storage_names[:default] = "payment_log"

#     property :id, Serial

#     property :user_id, Integer
#     belongs_to :user

#     property :payment_type_id, Integer, field: 'action'
#     belongs_to :payment_type

#     property :stored_card_id, Integer, field: 'stored_card'
#     belongs_to :credit_card, child_key: [ :stored_card_id ]
#     property :cc, String, length: 4
#     property :card_name, String, length: 80, default: ""
#     property :card_type, String, length: 10
#     property :cc_month, String, length: 2
#     property :cc_year, String, length: 4
#     property :price, Float
#     property :auth_code, String, length: 32

#     property :reference, String, length: 32, field: 'PNRef'

#     property :created_at, DateTime, field: 'created'
#     property :created_by_id, Integer, field: 'created_by'
#     belongs_to :created_by, model: 'User', child_key: [ :created_by_id ]

#     has 1, :related_transaction, model: 'Transaction', child_key: [ :transaction_number ], parent_key: [ :reference ]
#     has 1, :order_fee, model: 'OrderFee', child_key: [ :payment_id ]

class PaymentLog < ApplicationRecord
    # Associations
    belongs_to :user
    belongs_to :payment_type, foreign_key: 'payment_type_id'
    belongs_to :credit_card, foreign_key: 'stored_card_id'
    belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  
    has_one :related_transaction, class_name: 'Transaction', foreign_key: 'transaction_number', primary_key: 'reference'
    has_one :order_fee, foreign_key: 'payment_id'
  
    # Validations
    validates :cc, length: { is: 4 }
    validates :card_name, length: { maximum: 80 }
    validates :card_type, length: { maximum: 10 }
    validates :cc_month, length: { is: 2 }
    validates :cc_year, length: { is: 4 }
    validates :auth_code, length: { maximum: 32 }
    validates :reference, length: { maximum: 32 }
  
    # Optional: Define any default behavior
    # For example, you could default the card_name to an empty string:
    # after_initialize :set_defaults, if: :new_record?
  
    
  
    # Custom field names
    # ActiveRecord automatically assumes 'created_at' and 'updated_at' for timestamp columns.
    # You may use custom field names, or just rely on default ActiveRecord behavior.
    # For custom field names:
    # self.created_at = self.created  


    def order
        begin
            return nil unless order_fee
            return order_fee.order
        rescue
            return nil
        end
    end

    private
  
    def set_defaults
      self.card_name ||= ""
    end

end

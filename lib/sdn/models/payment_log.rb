class PaymentLog
    include DataMapper::Resource

    storage_names[:default] = "payment_log"

    property :id, Serial

    property :user_id, Integer
    belongs_to :user

    property :payment_type_id, Integer, field: 'action'
    belongs_to :payment_type

    property :stored_card_id, Integer, field: 'stored_card'
    belongs_to :credit_card, child_key: [ :stored_card_id ]
    property :cc, String, length: 4
    property :card_name, String, length: 80, default: ""
    property :card_type, String, length: 10
    property :cc_month, String, length: 2
    property :cc_year, String, length: 4
    property :price, Float
    property :auth_code, String, length: 32

    property :reference, String, length: 32, field: 'PNRef'

    property :created_at, DateTime, field: 'created'
    property :created_by_id, Integer, field: 'created_by'
    belongs_to :created_by, model: 'User', child_key: [ :created_by_id ]

    has 1, :related_transaction, model: 'Transaction', child_key: [ :transaction_number ], parent_key: [ :reference ]
    has 1, :order_fee, model: 'OrderFee', child_key: [ :payment_id ]

    def order
        begin
            return nil unless order_fee
            return order_fee.order
        rescue
            return nil
        end
    end
end

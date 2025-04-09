class Transaction
    include DataMapper::Resource

    property :id, Serial
    
    property :response, String, length: 20
    property :failure_reason, String, length: 200, allow_nil: true
    property :table_name, String, length: 40
    property :table_id, Integer
    property :amount, Decimal, precision: 10, scale: 2
    property :tax, Decimal, precision: 10, scale: 2, allow_nil: true
    property :type, String, length: 20

    property :check_number, String, length: 20, allow_nil: true
    property :check_date, DateTime, allow_nil: true
    property :check_note, String, length: 250, allow_nil: true
    property :cc_last_four, String, length: 4, allow_nil: true
    property :transaction_number, String, length: 50, allow_nil: true
    property :authorization_code, String, length: 20, allow_nil: true
    property :transaction_date, DateTime, default: ->(*) { Time.zone.now }
    property :processed_by, String, length: 40
    property :processed_with, String, length: 50
    property :refunded_transaction_id, Integer, allow_nil: true

    property :stored_card_id, Integer, allow_nil: true
    # belongs_to :credit_card, child_key: [ :stored_card_id ], required: false

    has 1, :details, model: 'TransactionDetail'

    def order
        return Order.get(table_id) if table_name == 'orders'
    end
    
    def self.for_order(order_id)
        all(table_name: 'orders', table_id: order_id)
    end

    def self.credit_card
        all(type: 'Credit Card')
    end
    
    def charge_account?
        type == 'Charge Account'
    end

    def credit_card?
        type == 'Credit Card'
    end

    def check?
        type == 'Check'
    end

    def cash?
        type == 'Cash'
    end
end

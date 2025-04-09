class RefundLog
    include DataMapper::Resource

    storage_names[:default] = "refund_log"
    
    property :id, Serial

    property :payment_id, Integer, index: true
    belongs_to :payment

    property :line_id, Integer, index: true
   # belongs_to :order_lines

    property :amount, Float

    property :type,  StringEnum['NULL','DEFAULT','Order','Membership','Fees','Others']

    property :refunded_by, Integer
   # belongs_to :users

    property :description, String, length: 250
    
    property :status,  StringEnum['NULL','DEFAULT','OK','REJECTED']

    property :timestamp, DateTime, field: 'timestamp'
 
    property :refund_payment_id, Integer, index: true
    belongs_to :payment

    property :reason, String, length: 100

    property :reason_description, String, length: 300

end
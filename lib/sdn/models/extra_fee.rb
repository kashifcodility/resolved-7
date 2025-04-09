class ExtraFee
    include DataMapper::Resource

    storage_names[:default] = 'extra_fees'

    property :id, Serial

    property :type, String, length: 32, index: true
    property :description, Text

    # FIXME: This should be a Decimal GFDMT!
    property :tax, Float, default: 0.0

    property :order_id, Integer, index: true
    belongs_to :order

    property :order_line_id, Integer, index: true
    belongs_to :order_line

    property :charged_by, Integer
    
    property :charged_id, Integer, default: 0
    belongs_to :payment, child_key: [ :charged_id ]

    property :updated_at, DateTime, field: 'timestamp'
end

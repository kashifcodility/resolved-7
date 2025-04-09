class Payment
    include DataMapper::Resource

    storage_names[:default] = "payment_log"

    property :id, Serial

    belongs_to :user

    property :action, Integer

    property :stored_card, Integer
    belongs_to :credit_card, child_key: [ :stored_card ]

    property :cc, String, length: 4
    property :cc_month, String, length: 2
    property :cc_year, String, length: 4
    property :auth_code, String, length: 32
    property :pn_ref, String, length: 32, field: "PNRef"

    property :card_name, String, length: 80
    property :card_type, String, length: 10

    # FIXME: this should be a Decimal GFDMT!
    property :price, Float

    property :created_at, DateTime, field: 'created'
end

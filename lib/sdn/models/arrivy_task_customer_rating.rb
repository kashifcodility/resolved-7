class ArrivyTaskCustomerRating
    include ::DataMapper::Resource

    storage_names[:default] = 'arrivy_task_customer_rating'

    property :id, Serial

    property :order_id, Integer
    belongs_to :order

    property :arrivy_task_id, Integer, max: 2**63
    property :arrivy_customer_id, Integer, max: 2**63, allow_nil: true

    property :rating, Decimal, precision: 4, scale: 2, allow_nil: true
    property :comments, Text, allow_nil: true

    property :created_at, DateTime
    property :updated_at, DateTime
end

class SdnOrderArrivyTask
    include ::DataMapper::Resource

    storage_names[:default] = 'sdn_order_arrivy_task'

    property :id, Serial

    property :order_id, Integer
    belongs_to :order

    property :arrivy_task_id, Integer, max: 2**63
    property :arrivy_customer_id, Integer, max: 2**63, allow_nil: true
    property :arrivy_destage_task_id, Integer, max: 2**63, allow_nil: true

    property :task_rescheduled_date, DateTime, allow_nil: true
    property :start_datetime, DateTime, allow_nil: true
    property :end_datetime, DateTime, allow_nil: true

    property :created_at, DateTime
    property :updated_at, DateTime
end

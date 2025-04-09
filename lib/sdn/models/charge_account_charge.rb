class ChargeAccountCharge
    include ::DataMapper::Resource

    property :id, Serial

    belongs_to :charge_account

    property :type, String, length: 20
    property :status, String, length: 10
    property :amount, Decimal, precision: 10, scale: 2
    property :table_name, String, length: 50
    property :table_id, Integer

    property :created_at, DateTime, field: "created"
    property :created_by, String, field: "created_by", length: 40
    property :created_with, String, length: 50
    property :updated_at, DateTime, field: "edited"
    property :updated_by, String, field: "edited_by", length: 40
    property :updated_with, String, field: "edited_with", length: 50

end

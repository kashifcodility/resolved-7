class TaxAuthority
    include DataMapper::Resource

    storage_names[:default] = "tax_authorities"

    property :id, Serial

    property :description, String, length: 100

    property :active, String, length: 10, default: "Active", index: true

    property :entry_mode, String, length: 10, default: "Auto"

    property :state_authority, String, length: 40
    property :county_authority, String, length: 40, allow_nil: true
    property :city_authority, String, length: 40, allow_nil: true
    property :special_authority, String, length: 40, allow_nil: true

    # TODO: dm-migrations: BigDecimal -> DECIMAL(), but Float -> FLOAT.
    # BigDecimal is deprecated now, not clear what field type DM will
    # materialize from class Decimal .. Confirm.
    property :state_rate, Decimal, precision: 10, scale: 7
    property :county_rate, Decimal, precision: 10, scale: 7, allow_nil: true
    property :city_rate, Decimal, precision: 10, scale: 7, allow_nil: true
    property :special_rate, Decimal, precision: 10, scale: 7, allow_nil: true

    property :total_rate, Decimal, precision: 10, scale: 7, allow_nil: true

    property :transaction_id, String, length: 15, allow_nil: true
    property :transaction_code, String, length: 40, allow_nil: true
    property :transaction_status, String, length: 50, allow_nil: true

    property :tax_rate_source, String, length: 25, allow_nil: true

    property :created_by, String, length: 40, default: 13
    property :created_with, String, length: 50
    property :created_at, DateTime, field: "created"
    property :updated_at, DateTime, field: "edited"
    property :updated_by, String, field: "edited_by", length: 40, default: 13
    property :updated_with, String, field: "edited_with", length: 50

end

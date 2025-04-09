# class TaxAuthority
#     include DataMapper::Resource

#     storage_names[:default] = "tax_authorities"

#     property :id, Serial

#     property :description, String, length: 100

#     property :active, String, length: 10, default: "Active", index: true

#     property :entry_mode, String, length: 10, default: "Auto"

#     property :state_authority, String, length: 40
#     property :county_authority, String, length: 40, allow_nil: true
#     property :city_authority, String, length: 40, allow_nil: true
#     property :special_authority, String, length: 40, allow_nil: true

#     # TODO: dm-migrations: BigDecimal -> DECIMAL(), but Float -> FLOAT.
#     # BigDecimal is deprecated now, not clear what field type DM will
#     # materialize from class Decimal .. Confirm.
#     property :state_rate, Decimal, precision: 10, scale: 7
#     property :county_rate, Decimal, precision: 10, scale: 7, allow_nil: true
#     property :city_rate, Decimal, precision: 10, scale: 7, allow_nil: true
#     property :special_rate, Decimal, precision: 10, scale: 7, allow_nil: true

#     property :total_rate, Decimal, precision: 10, scale: 7, allow_nil: true

#     property :transaction_id, String, length: 15, allow_nil: true
#     property :transaction_code, String, length: 40, allow_nil: true
#     property :transaction_status, String, length: 50, allow_nil: true

#     property :tax_rate_source, String, length: 25, allow_nil: true

#     property :created_by, String, length: 40, default: 13
#     property :created_with, String, length: 50
#     property :created_at, DateTime, field: "created"
#     property :updated_at, DateTime, field: "edited"
#     property :updated_by, String, field: "edited_by", length: 40, default: 13
#     property :updated_with, String, field: "edited_with", length: 50

# end


class TaxAuthority < ApplicationRecord
    # Setting the table name (if different from the default pluralized class name)
    self.table_name = "tax_authorities"
  
    # Associations (if any, but not defined in the original DataMapper model)
  
    # Validations (optional, based on your needs)
    validates :description, length: { maximum: 100 }
    validates :active, length: { maximum: 10 }
    validates :entry_mode, length: { maximum: 10 }
    validates :state_authority, length: { maximum: 40 }
    validates :county_authority, length: { maximum: 40 }, allow_nil: true
    validates :city_authority, length: { maximum: 40 }, allow_nil: true
    validates :special_authority, length: { maximum: 40 }, allow_nil: true
    validates :transaction_id, length: { maximum: 15 }, allow_nil: true
    validates :transaction_code, length: { maximum: 40 }, allow_nil: true
    validates :transaction_status, length: { maximum: 50 }, allow_nil: true
    validates :tax_rate_source, length: { maximum: 25 }, allow_nil: true
    validates :created_by, length: { maximum: 40 }
    validates :created_with, length: { maximum: 50 }
    validates :updated_by, length: { maximum: 40 }
    validates :updated_with, length: { maximum: 50 }
  
    # Optional default values can be set using callbacks or database defaults
    # after_initialize :set_default_values, if: :new_record?
  
    private
  
    def set_default_values
      self.active ||= "Active"
      self.entry_mode ||= "Auto"
      self.created_by ||= "13"
      self.updated_by ||= "13"
    end
end
  

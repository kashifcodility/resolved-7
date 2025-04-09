# class StagingInsuranceProof
#     include DataMapper::Resource

#     storage_names[:default] = "staging_insurance_proof"

#     property :id, Serial

#     belongs_to :user

#     # This is pretty fucking useless...
#     property :file, String, length: 30

#     property :status, String, length: 30, default: 'Requested'

#     property :expires_on, DateTime, allow_nil: true

class StagingInsuranceProof < ApplicationRecord
    # Setting the table name (if it's different from the default pluralized class name)
    self.table_name = "staging_insurance_proof"
  
    # Associations
    belongs_to :user
  
    # Validations (optional, if needed)
    validates :file, length: { maximum: 30 }, allow_nil: true
    validates :status, length: { maximum: 30 }
  
    # Optional default values can be set using callbacks or database defaults
    # after_initialize :set_default_values, if: :new_record?
  


    def self.valid
        where( status: 'Approved') & (where( expires_on: nil ) | where( 'expires_on >= ?',Time.zone.today.to_date ))
    end

    def self.expired
        all( status: 'Approved', :expires_on.lt => Time.zone.now.to_date )
    end
    private
  
    def set_default_values
      self.status ||= 'Requested'
    end
end

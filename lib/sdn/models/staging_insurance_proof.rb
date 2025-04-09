class StagingInsuranceProof
    include DataMapper::Resource

    storage_names[:default] = "staging_insurance_proof"

    property :id, Serial

    belongs_to :user

    # This is pretty fucking useless...
    property :file, String, length: 30

    property :status, String, length: 30, default: 'Requested'

    property :expires_on, DateTime, allow_nil: true

    def self.valid
        all( status: 'Approved') & (all( expires_on: nil ) | all( :expires_on.gte => Time.zone.today.to_date ))
    end

    def self.expired
        all( status: 'Approved', :expires_on.lt => Time.zone.now.to_date )
    end
end

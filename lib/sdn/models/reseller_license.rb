class ResellerLicense
    include DataMapper::Resource

    property :id, Serial

    belongs_to :user

    property :status, String, length: 10
    property :file, String, length: 200, allow_nil: true
    property :approved_date, DateTime, allow_nil: true
    property :inactive_date, DateTime, allow_nil: true

    property :created_at, DateTime, field: "created"
    property :created_by, String, field: "created_by", length: 40
    property :created_with, String, length: 50
    property :updated_at, DateTime, field: "edited"
    property :updated_by, String, field: "edited_by", length: 40
    belongs_to :updated_by, model: 'User', child_key: [ :updated_by ]
    property :updated_with, String, field: "edited_with", length: 50


    def self.valid_at(date=nil)
        self.approved & self.active(date)
    end
    
    def self.valid
        self.approved & self.active
    end
    
    def self.approved
        all(status: 'Approved')
    end

    def self.active(date=nil)
        date ||= Date.today
        all(:inactive_date.gte => date) | all(inactive_date: nil)
    end

end

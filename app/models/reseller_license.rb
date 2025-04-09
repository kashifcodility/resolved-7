# class ResellerLicense
#     include DataMapper::Resource

#     property :id, Serial

#     belongs_to :user

#     property :status, String, length: 10
#     property :file, String, length: 200, allow_nil: true
#     property :approved_date, DateTime, allow_nil: true
#     property :inactive_date, DateTime, allow_nil: true

#     property :created_at, DateTime, field: "created"
#     property :created_by, String, field: "created_by", length: 40
#     property :created_with, String, length: 50
#     property :updated_at, DateTime, field: "edited"
#     property :updated_by, String, field: "edited_by", length: 40
#     belongs_to :updated_by, model: 'User', child_key: [ :updated_by ]
#     property :updated_with, String, field: "edited_with", length: 50

class ResellerLicense < ApplicationRecord
    # Associations
    belongs_to :user
    belongs_to :updated_by_user, class_name: 'User', foreign_key: 'updated_by', optional: true
  
    # Validations (if needed)
    validates :status, length: { maximum: 10 }
    validates :file, length: { maximum: 200 }, allow_nil: true
    validates :created_by, length: { maximum: 40 }, allow_nil: true
    validates :created_with, length: { maximum: 50 }, allow_nil: true
    validates :updated_by, length: { maximum: 40 }, allow_nil: true
    validates :updated_with, length: { maximum: 50 }, allow_nil: true
  
    # Timestamp fields: Rails automatically handles `created_at` and `updated_at`
    # These fields are automatically managed by ActiveRecord, but we keep them for clarity.
    # If your table does not use default timestamp fields, you can manually define them below.
    
    # You may add custom getter/setter methods for 'approved_date' and 'inactive_date' if required.  


    def self.valid_at(date=nil)
        self.approved & self.active(date)
    end
    
    def self.valid
        self.approved & self.active
    end
    
    def self.approved
        where(status: 'Approved')
    end

    def self.active(date=nil)
        date ||= Date.today
        # all(:inactive_date.gte => date) | all(inactive_date: nil)
        where('inactive_date >= ? OR inactive_date IS NULL', date)
    end

end

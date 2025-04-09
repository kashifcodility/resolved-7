class UserMembershipProof
    include DataMapper::Resource

    property :id, Serial

    belongs_to :user

    property :action, String, length: 15, default: 'Registration'
    property :file, String, length: 500
    property :status, String, length: 10
    property :price, Decimal, precision: 10, scale: 2, allow_nil: true, default: 39.99
    property :term_length, Integer, default: 1
    property :promo, Text, allow_nil: true
    
    property :approved_date, DateTime, allow_nil: true
    property :inactive_date, DateTime, allow_nil: true

    property :created_at, DateTime, field: "created"
    property :created_by, String, field: "created_by", length: 40
    property :updated_at, DateTime, field: "edited"
    property :updated_by, String, field: "edited_by", length: 40
end

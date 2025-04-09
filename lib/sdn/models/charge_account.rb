class ChargeAccount
    include ::DataMapper::Resource

    property :id, Serial

    belongs_to :user

    property :account_number, String, length: 20
    property :active, String, length: 10

    property :created_at, DateTime, field: 'created'
    property :updated_at, DateTime, field: 'edited'

    property :created_at, DateTime, field: "created"
    property :created_by, String, field: "created_by", length: 40
    property :created_with, String, length: 50
    property :updated_at, DateTime, field: "edited"
    property :updated_by, String, field: "edited_by", length: 40
    property :updated_with, String, field: "edited_with", length: 50

    # Not sure what this is used for
    property :original_id, Integer, allow_nil: true

    def belongs_to_user?(user)
        self.active == 'Active' && user.id == self.user_id
    end
end

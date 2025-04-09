class UserMembershipLevel
    include DataMapper::Resource

    property :id, Serial

    belongs_to :user
    belongs_to :membership_level

    property :price, Decimal, precision: 10, scale: 2
    property :term_length, Integer, default: 1

    property :start_date, DateTime

    property :created_by, String, length: 40
    property :created_with, String, length: 50

    def self.create_user_membership(user, created_with: 'UserSignup', created_by: 'admin')
        if uml = create(
            user_id: user.id,
            membership_level_id: 1,
            price: 0.00,
            start_date: Time.zone.now,
            created_by: created_by,
            created_with: created_with,
           )
            $LOG.info "User membership level created: [user: #{user.email}]"
        else
            $LOG.error "User membership level NOT created: [user: #{user.email}] #{uml.errors.inspect}"
        end
    end
end

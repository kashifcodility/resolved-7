# class UserMembershipLevel
#     include DataMapper::Resource

#     property :id, Serial

#     belongs_to :user
#     belongs_to :membership_level

#     property :price, Decimal, precision: 10, scale: 2
#     property :term_length, Integer, default: 1

#     property :start_date, DateTime

#     property :created_by, String, length: 40
#     property :created_with, String, length: 50

class UserMembershipLevel < ApplicationRecord
    # Setting the table name (if different from the default pluralized class name)
    self.table_name = "user_membership_levels"
  
    # Associations
    belongs_to :user
    belongs_to :membership_level
  
    # Validations (optional, based on your needs)
    validates :price, numericality: { greater_than_or_equal_to: 0 }
    validates :term_length, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :start_date, presence: true
    validates :created_by, length: { maximum: 40 }
    validates :created_with, length: { maximum: 50 }
  
    # Optional: Handle any default values or callbacks if necessary
    # For example, you could add a callback to set default values or handle any logic.

    def self.create_user_membership(user, created_with: 'UserSignup', created_by: 'admin')
        if uml = create(
            user_id: user.id,
            membership_level_id: 1,
            price: 0.00,
            start_date: Time.zone.now,
            created_by: created_by,
            created_with: created_with,
           )
            Rails.logger.info "User membership level created: [user: #{user.email}]"
        else
            Rails.logger.error "User membership level NOT created: [user: #{user.email}] #{uml.errors.inspect}"
        end
    end
end

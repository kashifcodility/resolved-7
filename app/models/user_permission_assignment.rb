# class UserPermissionAssignment
#   include DataMapper::Resource

#   const_def :IMMUTABLE_ASSIGNMENTS, [ :edit_employee_permissions ]
  
#   property :id, Serial
  
#   property :user_id, Integer,            :unique_index => :uniqueness, required: true
#   property :user_permission_id, Integer, :unique_index => :uniqueness, required: true
#   property :site_id, Integer,            :unique_index => :uniqueness, required: true
  
#   belongs_to :user
#   belongs_to :permission, 'UserPermission', child_key: [ :user_permission_id ]
#   belongs_to :site
  
#   timestamps :at
# end


class UserPermissionAssignment < ApplicationRecord
    # Define the constant IMMUTABLE_ASSIGNMENTS
    IMMUTABLE_ASSIGNMENTS = [:edit_employee_permissions]
  
    # Associations
    belongs_to :user
    belongs_to :permission, class_name: 'UserPermission', foreign_key: 'user_permission_id'
    belongs_to :site
  
    # Validations
    validates :user_id, :user_permission_id, :site_id, presence: true
    validates :user_id, uniqueness: { scope: [:user_permission_id, :site_id] }
  
    # ActiveRecord automatically handles timestamps
end  
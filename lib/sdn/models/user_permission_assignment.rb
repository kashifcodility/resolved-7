class UserPermissionAssignment
    include DataMapper::Resource

    const_def :IMMUTABLE_ASSIGNMENTS, [ :edit_employee_permissions ]
    
    property :id, Serial
    
    property :user_id, Integer,            :unique_index => :uniqueness, required: true
    property :user_permission_id, Integer, :unique_index => :uniqueness, required: true
    property :site_id, Integer,            :unique_index => :uniqueness, required: true
    
    belongs_to :user
    belongs_to :permission, 'UserPermission', child_key: [ :user_permission_id ]
    belongs_to :site
    
    timestamps :at
end

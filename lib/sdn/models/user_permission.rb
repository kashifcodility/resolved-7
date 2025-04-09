class UserPermission
    include DataMapper::Resource

    property :id, Serial
    property :name, String, index: true, unique: true
    property :label, String
    property :description, String, allow_nil: true, length: 255

    property :parent_id, Integer, allow_nil: true
    
    belongs_to :parent_permission, 'UserPermission', :child_key => [ :parent_id ]
    has n, :child_permissions, 'UserPermission', :child_key => [ :parent_id ]

    def self.with_children(id:)
        all(id: id) | all(parent_id: id)
    end
end

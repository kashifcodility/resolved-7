
# class UserPermission
#   include DataMapper::Resource

#   property :id, Serial
#   property :name, String, index: true, unique: true
#   property :label, String
#   property :description, String, allow_nil: true, length: 255

#   property :parent_id, Integer, allow_nil: true
  
#   belongs_to :parent_permission, 'UserPermission', :child_key => [ :parent_id ]
#   has n, :child_permissions, 'UserPermission', :child_key => [ :parent_id ]

#   def self.with_children(id:)
#       all(id: id) | all(parent_id: id)
#   end
# end
class UserPermission < ApplicationRecord
    # Attributes
    validates :name, presence: true, uniqueness: true
    validates :label, presence: true
    validates :description, length: { maximum: 255 }, allow_nil: true
    validates :parent_id, numericality: { only_integer: true }, allow_nil: true
  
    # Associations
    belongs_to :parent_permission, class_name: 'UserPermission', optional: true, foreign_key: 'parent_id'
    has_many :child_permissions, class_name: 'UserPermission', foreign_key: 'parent_id'
  
    # Class Method for finding permission with children
    def self.with_children(id:)
      where(id: id).or(where(parent_id: id))
    end
end  
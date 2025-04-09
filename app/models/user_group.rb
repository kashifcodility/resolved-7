# class UserGroup
#     include DataMapper::Resource
  
#     storage_names[:default] = "user_groups"
  
#     property :id, Serial
#     property :group_name, String, length: 100
#     property :discount_percentage, Decimal, precision: 10, scale: 2 
#     property :active, String, length: 100
  
#     has n, :users, model: 'User', child_key: [:group_id]  
# end

class UserGroup < ApplicationRecord
  self.table_name = "user_groups"

  validates :group_name, length: { maximum: 100 }
  validates :discount_percentage, numericality: { precision: 10, scale: 2 }
  validates :active, length: { maximum: 100 }

  has_many :users, foreign_key: :group_id
end
  
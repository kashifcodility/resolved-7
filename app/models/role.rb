# class Role
#     include DataMapper::Resource
    
#     property :id, Serial
#     property :role, String
    
#     # Define many-to-many relationship with User
#     has n, :user_roles
#     has n, :users, through: :user_roles
# end


class Role < ApplicationRecord
  has_many :user_roles
  has_many :users, through: :user_roles
end
  
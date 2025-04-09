# class UserRole
#     include DataMapper::Resource

#     property :id, Serial
    
#     belongs_to :user
#     belongs_to :role
#   end


class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
end
  
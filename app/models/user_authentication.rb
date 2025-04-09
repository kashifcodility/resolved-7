# class UserAuthentication
#     include DataMapper::Resource
#     storage_names[:default] = 'user_authentication'
#     property :id, Serial
#     property :created, DateTime
#     property :auth_code, String
    
#     # property :user_id, Integer
    
#     belongs_to :user
    
# end




class UserAuthentication < ApplicationRecord
    self.table_name = 'user_authentication'
    
    # attribute :id, :integer, primary_key: true
    # attribute :created, :datetime
    # attribute :auth_code, :string
    
    # attribute :user_id, :integer
    
    belongs_to :user
end

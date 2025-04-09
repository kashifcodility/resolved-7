# class IntuitAccount
#     include DataMapper::Resource
#     include QuickbooksOauth


#     property :id, Serial

#     property :oauth2_access_token, String, length: 1100
#     property :realm_id, String, length: 40
#     property :oauth2_refresh_token, String, length: 240
#     property :oauth2_access_token_expires_at, DateTime
#     property :oauth2_refresh_token_expires_at, DateTime


#     def self.quickbooks_connected?
#      self.count == 1
#     end
# end






class IntuitAccount < ApplicationRecord
    include QuickbooksOauth

    def self.quickbooks_connected?
        self.count == 1
    end
end

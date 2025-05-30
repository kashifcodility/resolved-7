class Tier < ApplicationRecord
    self.table_name = "tiers"

    # property :id, Serial

    # property :price, Integer
    # property :default, Boolean
    # property :projects_limit, Integer
    # property :users_limit, Integer
    # property :products_limit, Integer
    # property :name, String, length: 200, allow_nil: true
    
    has_many :sites
    
end

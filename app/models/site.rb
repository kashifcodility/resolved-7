# class Site
#     include DataMapper::Resource

#     storage_names[:default] = "sites"

#     property :id, Serial

#     property :active, String, length: 10, allow_nil: true, default: "Active"

#     property :site, String, length: 20
#     alias_method :name, :site

#     property :default_address_id, Integer, allow_nil: true
#     belongs_to :address, child_key: [ :default_address_id ]

#     property :default_contact_id, Integer, allow_nil: true
#     property :receive_bin_id, Integer, allow_nil: true
#     property :pick_bin_id, Integer, allow_nil: true
#     property :will_call_bin_id, Integer, allow_nil: true

#     property :type, String, length: 30, default: "Site"

#     property :email, String, length: 100, allow_nil: true

#     # NOTE: need to make sure these still work; underlying field for created is
#     # TIMESTAMP in this case
#     property :created_at, DateTime, field: 'created'
#     property :updated_at, DateTime, field: 'edited'

#     property :tax_authority_id, Integer, index: true
#     belongs_to :tax_authority

#     belongs_to :location, required: false

#     has n, :users
#     has n, :products

#     # TODO: Add this to the DB
#     # Kirkland/Everett: Seattle
#     # Phoenix: Phoenix
#     def region
#         self.site == 'Phoenix' ? self.site : 'Seattle'
#     end

#     def self.active
#         all( active: 'Active' )
#     end
# end

class Site < ApplicationRecord
    self.table_name = "sites"
  
    validates :active, length: { maximum: 10 }, allow_nil: true
    validates :site, length: { maximum: 20 }
    
    alias_attribute :name, :site
  
    belongs_to :address, optional: true, foreign_key: :default_address_id
    belongs_to :tax_authority, optional: true
    belongs_to :location, optional: true
  
    has_many :users
    has_many :products
    belongs_to :tier
    validates :email, length: { maximum: 100 }, allow_nil: true
    has_one :subscription, class_name: 'Subscription'
    # Enum or fixed string for 'type' property, using 'Site' as default
    # validates :type, length: { maximum: 30 }
  
    # Additional foreign keys
    validates :default_contact_id, :receive_bin_id, :pick_bin_id, :will_call_bin_id, numericality: { only_integer: true }, allow_nil: true
  
    # Timestamps (mapped from 'created' and 'edited' columns in the database)
    # self.timestamp_attributes_for_create = [:created]
    # self.timestamp_attributes_for_update = [:edited]
  
    # Custom method to return region based on site
    def region
      site == 'Phoenix' ? site : 'Seattle'
    end

    def self.active
        where(active: 'Active') 
    end
end

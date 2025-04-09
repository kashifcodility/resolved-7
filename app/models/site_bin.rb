# class SiteBin
#     include DataMapper::Resource

#     storage_names[:default] = "site_bins"

#     property :id, Serial

#     property :active, String, length: 10, allow_nil: true, default: "Active"

   
    

#     property :bin, String, length: 200

#     property :default_bin, Integer

#     property :show_on_frontend, Integer

#     property :default_pick_bin, Integer

#     property :default_will_call_bin, Integer

   
#     belongs_to :site

  
# end

class SiteBin < ApplicationRecord
    # Setting the table name (if different from the default pluralized class name)
    self.table_name = "site_bins"
  
    # Associations
    belongs_to :site
  
    # Validations (optional, if needed)
    validates :bin, length: { maximum: 200 }
    validates :active, length: { maximum: 10 }, allow_nil: true
  
    # Optional default values can be set using callbacks or database defaults
    # Example: default value for 'active' column can be set in a migration as well.
    # after_initialize :set_default_values, if: :new_record?
  
    private
  
    def set_default_values
      self.active ||= "Active"
    end
end
  

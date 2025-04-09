# class Bin
#     include DataMapper::Resource

#     storage_names[:default] = "site_bins"

#     property :id, Serial

#     belongs_to :site
    
#     property :active, String, length: 10
#     property :bin, String, length: 20
#     alias_method :name, :bin
#     property :default_bin, Integer
#     has n, :products
#     #belongs_to :barcode
# end

class Bin < ApplicationRecord
    self.table_name = "site_bins"

    belongs_to :site

    validates :active, length: { maximum: 10 }
    validates :bin, length: { maximum: 20 }
    
    alias_attribute :name, :bin

    has_many :products
    # belongs_to :barcode
end

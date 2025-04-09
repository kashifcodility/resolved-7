class Bin
    include DataMapper::Resource

    storage_names[:default] = "site_bins"

    property :id, Serial

    belongs_to :site
    
    property :active, String, length: 10
    property :bin, String, length: 20
    alias_method :name, :bin
    property :default_bin, Integer

    #belongs_to :barcode
end

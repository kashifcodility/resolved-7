class ServiceCategory
    include DataMapper::Resource

    storage_names[:default] = 'service_categories'

    property :id, Serial

    property :service_category, String, length: 50
    property :active, String, length: 10, default: "Active"
    property :suggested, Integer, default: 0, allow_nil: true
    property :sequence, Integer, default: 2
end

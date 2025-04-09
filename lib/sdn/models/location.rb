class Location
    include DataMapper::Resource

    property :id, Serial

    property :location, String, length: 30

    # NOTE: this is likely unused, not bothering with a model
    property :warehouse_id, Integer, default: 1

    # NOTE: different than usual length=>10 definition
    property :active, String, length: 15, default: "Active"

end

class Floor
    include DataMapper::Resource

    property :id, Serial

    property :name, String, length: 64

    has n, :order_lines
end
class ProductImage
    include DataMapper::Resource

    property :id, Serial

    belongs_to :product
    belongs_to :image

    property :image_order, Integer
    alias_method :display_order, :image_order

end
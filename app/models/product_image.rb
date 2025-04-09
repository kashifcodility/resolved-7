# class ProductImage
#     include DataMapper::Resource

#     property :id, Serial

#     belongs_to :product
#     belongs_to :image

#     property :image_order, Integer
#     alias_method :display_order, :image_order

# end


class ProductImage < ApplicationRecord
    belongs_to :product
    belongs_to :image

    # attribute :image_order, :integer
    alias_attribute :display_order, :image_order
end

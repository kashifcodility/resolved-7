# class UserWishlist
#     include DataMapper::Resource

#     storage_names[:default] = "user_wishlist"

#     property :id, Serial

#     property :user_id, Integer, allow_nil: false
#     belongs_to :user

#     property :product_id, Integer, allow_nil: false
#     belongs_to :product
# end


class UserWishlist < ApplicationRecord
    self.table_name = "user_wishlist"

    belongs_to :user
    belongs_to :product
end

# Product is reserved and in this model if the items exists in their session cart
# class ProductReservation
#     include ::DataMapper::Resource

#     property :id, Serial

#     property :product_id, Integer
#     belongs_to :product

#     property :user_id, Integer
#     belongs_to :user

#     property :created_at, DateTime
# end


class ProductReservation < ApplicationRecord
    belongs_to :product
    belongs_to :user

    validates :product_id, presence: true
    validates :user_id, presence: true
end

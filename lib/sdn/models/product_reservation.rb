# Product is reserved and in this model if the items exists in their session cart
class ProductReservation
    include ::DataMapper::Resource

    property :id, Serial

    property :product_id, Integer
    belongs_to :product

    property :user_id, Integer
    belongs_to :user

    property :created_at, DateTime
end

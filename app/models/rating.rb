# class Rating
#     include DataMapper::Resource
    
#     property :id, Serial
#     property :review_star, Integer
#     property :order_id, Integer
#     belongs_to :user
#     # belongs_to :order
#     belongs_to :product
# end
  

class Rating < ApplicationRecord
  belongs_to :user
  # belongs_to :order
  belongs_to :product

  validates :review_star, presence: true, numericality: { only_integer: true }
  validates :order_id, presence: true, numericality: { only_integer: true }
end

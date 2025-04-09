# class CategoryCount
#     include DataMapper::Resource

#     property :id, Serial

#     belongs_to :category

#     property :count, Integer, default: 0
#     property :updated_at, DateTime

# end

class CategoryCount < ApplicationRecord
    belongs_to :category

    validates :count, numericality: { only_integer: true }, default: 0
end

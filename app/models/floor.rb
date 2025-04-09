# class Floor
#     include DataMapper::Resource

#     property :id, Serial

#     property :name, String, length: 64

#     has n, :order_lines
# end

class Floor < ApplicationRecord
    has_many :order_lines

    validates :name, length: { maximum: 200 }
end

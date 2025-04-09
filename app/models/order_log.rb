# class OrderLog
#     include DataMapper::Resource

#     property :id, Serial

#     property :order_id, Integer
#     property :product_pieces, Text

#     property :created_at, DateTime

#     belongs_to :order
# end


class OrderLog < ApplicationRecord
    self.table_name = 'order_logs'

    validates :order_id, presence: true
    validates :product_pieces, presence: true

    belongs_to :order
end

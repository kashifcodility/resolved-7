# class OrderLineDetail
#     include DataMapper::Resource

#     storage_names[:default] = "order_lines_detail"

#     property :order_line_id, Integer, field: 'order_lines_id', index: true, key: true
#     belongs_to :order_line, child_key: [ :order_line_id  ]

#     property :ordered_at,  DateTime, field: 'ordered',  allow_nil: true
#     property :shipped_at,  DateTime, field: 'shipped',  allow_nil: true
#     property :returned_at, DateTime, field: 'returned', allow_nil: true

class OrderLineDetail < ApplicationRecord
    # Associations
    belongs_to :order_line, foreign_key: :order_line_id
  
    # Validations (optional)
    validates :order_line_id, presence: true

    def product
        order_line&.product
    end

    def returned?
        returned_at.present?
    end
end

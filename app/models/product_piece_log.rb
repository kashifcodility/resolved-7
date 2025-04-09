# class ProductPieceLog
#     include DataMapper::Resource
#     storage_names[:default] = "product_pieces_logs"
#     property :id, Serial

#     property :product_id, Integer
#     property :order_line_id, Integer
#     property :previous_order_line_id, Integer
#     property :product_epc_id, Integer
#     property :confirm, Integer
#     property :epc_code, String
#     property :previous_status, String
#     property :status, String

#     property :created_at, DateTime
#     property :updated_at, DateTime
#     property :confirmed_at, DateTime
#     property :added_by, Integer
#     property :confirmed_by, Integer
    
# end



class ProductPieceLog < ApplicationRecord
    self.table_name = "product_pieces_logs"

    validates :product_id, :order_line_id, :previous_order_line_id, :product_epc_id, :confirm, :epc_code, :previous_status, :status, :added_by, :confirmed_by, presence: true

    validates :product_id, :order_line_id, :previous_order_line_id, :product_epc_id, :confirm, :added_by, :confirmed_by, numericality: { only_integer: true }

    validates :epc_code, :previous_status, :status, length: { maximum: 255 }

    validates :created_at, :updated_at, :confirmed_at, presence: true
end

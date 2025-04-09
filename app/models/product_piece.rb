# class ProductPiece
#     include ::DataMapper::Resource

#     storage_names[:default] = 'product_pieces'

#     property :id, Serial
#     property :product_epc_id, String, length: 200
#     property :epc_code, String, length: 200

#     property :status, String, length: 70

#     property :product_id, Integer
#     property :site_id, Integer
#     property :bin_id, Integer
#     belongs_to :product

#     # The order the product was originally added to the system by
#     property :order_line_id, Integer, allow_nil: true
#     # belongs_to :order_line, required: false

#     has n, :product_piece_locations

class ProductPiece < ApplicationRecord
    # Set the table name explicitly if different from the default
    self.table_name = 'product_pieces'
  
    # Associations
    belongs_to :product
    belongs_to :order_line, optional: true # Allow nil if the relationship is not required
  
    # Has many association for product_piece_locations
    has_many :product_piece_locations
  
    # Columns
    validates :product_epc_id, presence: true, length: { maximum: 200 }
    validates :epc_code, presence: true, length: { maximum: 200 }
    validates :status, length: { maximum: 70 }
    validates :product_id, presence: true
    validates :site_id, presence: true
    validates :bin_id, presence: true
  
    # If you need to track timestamps, you can uncomment the line below
    # t.timestamps  

    # NOTE: A piece can be voided when added in the admin by mistake.
    #       Example: Admin user adds new product with one barcode. They accidentally add a second
    #       barcode and then need to undo that mistake. The product piece location record is voided.
    def void?
        product_piece_locations.not_void.count < 1
    end
end

class ProductPiece
    include ::DataMapper::Resource

    storage_names[:default] = 'product_pieces'

    property :id, Serial

    property :product_id, Integer
    belongs_to :product

    # The order the product was originally added to the system by
    property :order_line_id, Integer, allow_nil: true
    belongs_to :order_line

    has n, :product_piece_locations

    # NOTE: A piece can be voided when added in the admin by mistake.
    #       Example: Admin user adds new product with one barcode. They accidentally add a second
    #       barcode and then need to undo that mistake. The product piece location record is voided.
    def void?
        product_piece_locations.not_void.count < 1
    end
end

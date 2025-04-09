# class ProductPieceLocation
#     include ::DataMapper::Resource

#     storage_names[:default] = 'product_piece_locations'

#     property :id, Serial

#     property :product_piece_id, Integer
#     belongs_to :product_piece

#     # NOTE: The DB does not express a default value for this field
#     property :log_status, StringEnum['Pending', 'Posted'], default: 'Pending'
#     property :log_type, StringEnum['OnOrder', 'Received', 'Available', 'Picked', 'Transfer', 'Shipped',
#                                   'Returned', 'InTransit', 'Pulled']

#     property :table_name, StringEnum['bins', 'orders']
#     property :table_id, Integer

#     property :created_at, DateTime, field: 'created', index: true

#     # I laughed out loud... WTF
#     property :created_by, String, length: 30
#     # belongs_to :user, child_key: [ :created_by ]

#     property :void, StringEnum['yes', 'no'], default: 'no'

#     property :voided_date, DateTime, allow_nil: true
#     property :voided_by, String, length: 40, allow_nil: true

#     property :pick_up_sdn, String, length: 45, allow_nil: true

#     property :order_line_id, Integer, allow_nil: true
class ProductPieceLocation < ApplicationRecord
    # Set the table name explicitly if different from the default
    self.table_name = 'product_piece_locations'
  
    # Associations
    belongs_to :product_piece, optional: true # If the association is optional, you can specify it
    # belongs_to :user, foreign_key: 'created_by', optional: true # If you have a user association
  
    # Enum fields (ActiveRecord equivalent to StringEnum)
    enum log_status: { pending: 'Pending', posted: 'Posted' }, _default: :pending
    enum log_type: {
      on_order: 'OnOrder',
      received: 'Received',
      available: 'Available',
      picked: 'Picked',
      transfer: 'Transfer',
      shipped: 'Shipped',
      returned: 'Returned',
      in_transit: 'InTransit',
      pulled: 'Pulled'
    }
    enum table_name_enum: { bins: 'bins', orders: 'orders' }
    enum void: { yes: 'yes', no: 'no' }, _default: :no
  
    # Validations
    validates :product_piece_id, presence: true
    validates :log_status, presence: true
    validates :log_type, presence: true
    validates :table_name, presence: true
    validates :table_id, presence: true
  
    # Columns mapping
    # Please ensure that the column names match exactly with your database schema.
    # You might need to create a migration if the table structure is not already in place.
  
    # Add timestamps
    # Uncomment if your table has 'created_at' and 'updated_at' columns
    # t.timestamps
    

    def self.void_by_order_line(line_id, voided_by:nil)
        ppl_ids = ProductPieceLocation.for_order_line_not_voided(line_id).pluck(:id).map(&:to_i)
        ppls = ProductPieceLocation.all(id: ppl_ids)

        $DB.transaction do
            ppls.each do |ppl|
                return false unless ppl.void!(voided_by: voided_by)
            end
        end

        $LOG.info "Product piece locations for order line voided: %i [user: %s, ppl ids: %s]" % [ line_id, voided_by&.email, ppl_ids.join('/') ]
        return true
    end

    # Returns all product piece locations that aren't voided that belong to a specific order line
    def self.for_order_line_not_voided(line_id)
        return $DB.select <<-FOO
            SELECT l.id, l.product_piece_id, l.table_id as order_id,l.log_type,l.log_status, p.product, p.description, ol.price
            FROM product_piece_locations AS l
                LEFT JOIN product_pieces AS pc ON pc.id = l.product_piece_id
                INNER JOIN order_lines ol ON ol.product_id = pc.product_id
                INNER JOIN orders o ON o.id = ol.order_id AND o.id = l.table_id AND table_name = 'orders'
                LEFT JOIN products p ON p.id = ol.product_id
            WHERE ol.id = #{line_id.to_i}
            AND l.void != 'yes'
        FOO
    end

    def void!(voided_by:nil)
        self.void = 'yes'
        self.voided_date = Time.zone.now
        self.voided_by = voided_by&.id.to_s

        if self.save
            $LOG.info "Product piece location voided: %i [user: %s]" % [ self.id, voided_by&.email ]
            return self
        else
            $LOG.error "Product piece location NOT voided: %i [user: %s] %s" % [ self.id, voided_by&.email, self.errors.inspect ]
        end
    end

    def self.not_void
        all(void: 'no')
    end
end

class ProductPieceLocation
    include ::DataMapper::Resource

    storage_names[:default] = 'product_piece_locations'

    property :id, Serial

    property :product_piece_id, Integer
    belongs_to :product_piece

    # NOTE: The DB does not express a default value for this field
    property :log_status, StringEnum['Pending', 'Posted'], default: 'Pending'
    property :log_type, StringEnum['OnOrder', 'Received', 'Available', 'Picked', 'Transfer', 'Shipped',
                                  'Returned', 'InTransit', 'Pulled']

    property :table_name, StringEnum['bins', 'orders']
    property :table_id, Integer

    property :created_at, DateTime, field: 'created', index: true

    # I laughed out loud... WTF
    property :created_by, String, length: 30
    # belongs_to :user, child_key: [ :created_by ]

    property :void, StringEnum['yes', 'no'], default: 'no'

    property :voided_date, DateTime, allow_nil: true
    property :voided_by, String, length: 40, allow_nil: true

    property :pick_up_sdn, String, length: 45, allow_nil: true

    property :order_line_id, Integer, allow_nil: true

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

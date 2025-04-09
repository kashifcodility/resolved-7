class OrderLine
    include DataMapper::Resource

    storage_names[:default] = "order_lines"

    const_def :VOID_THRESHOLD_DAYS, 2 # Order is voidable until X business days before scheduled delivery

    property :id, Serial

    property :order_id, Integer, index: true
    property :quantity, Integer
    belongs_to :order

    has 0..n, :extra_fees

    property :product_id, Integer, allow_nil: true, index: true
    belongs_to :product

    property :price, Decimal, precision: 10, scale: 4, allow_nil: true
    property :base_price, Decimal, precision: 10, scale: 4, allow_nil: true

    def tax
        price - base_price
    end

    property :description, String, length: 32, allow_nil: true
    property :reference, String, length: 10, index: true, allow_nil: true

    property :self_rental_pre_credited, String, length: 5, allow_nil: true, default: "No"
    def self_rental_pre_credited?() self_rental_pre_credited =~ /yes/i end


    property :change_confirmed, String, length: 5, allow_nil: true
    def change_confirmed?() change_confirmed =~ /yes/i end

    property :void, String, length: 3, default: "No"
    def void?() void =~ /yes/i end
    alias_method :voided?, :void?
    property :voided_date, DateTime, allow_nil: true
    alias_method :voided_on, :voided_date
    property :voided_by, Integer, allow_nil: true
    belongs_to :voided_by_user, model: 'User', child_key: [ :voided_by ]

    # FIXME: refunded_on is missing from DB!!
    property :refunded, String, length: 10, index: true, allow_nil: true, default: "No"
    def refunded?() refunded =~ /yes/i end
    # FIXME: refunded_by isn't a string.. WTF is it?
    property :refunded_by, Integer, allow_nil: true

    property :room_id, Integer, default: 20, index: true
    belongs_to :room

    property :floor_id, Integer, default: 1, index: true
    belongs_to :floor

    has 1, :detail, model: 'OrderLineDetail', child_key: [ :order_line_id ]

    # NOTE: Gets first product's product piece on order date
    # TODO: Update this to use the OrderLineDetail model
    def created_at(show_void: false)
        return unless product&.product_pieces
        filters = { table_name: 'orders', table_id: order_id, log_type: 'OnOrder', product_piece_id: product.product_pieces.pluck(:id), order: [ :id.asc ] }
        filters[:void] = 'no' unless show_void
        onorder_logs = ProductPieceLocation.all(filters)
        onorder_logs_piece_ids = onorder_logs.pluck(:product_piece_id)
        all_product_piece_ids = product.product_pieces.pluck(:id)

        unscanned_onorder_pieces = all_product_piece_ids - onorder_logs_piece_ids
        if onorder_logs.any? and unscanned_onorder_pieces.any?
            $LOG.debug "Order line #created_at - not all barcodes have been scanned OnOrder: [line: %i, order: %i, piece(s): %s]" % [ id, order_id, unscanned_onorder_pieces.join(',') ]
        end

        return onorder_logs.first&.created_at
    end

    # NOTE: Gets first product's product piece return date
    # TODO: Update this to use the OrderLineDetail model
    def returned_at
        return unless product&.product_pieces
        returned_logs = ProductPieceLocation.all(table_name: 'orders', table_id: order_id, log_type: 'Returned', void: 'no', product_piece_id: product.product_pieces.pluck(:id), order: [ :id.desc ])
        returned_logs_piece_ids = returned_logs.pluck(:product_piece_id)
        all_product_piece_ids = product.product_pieces.pluck(:id)

        unscanned_return_pieces = all_product_piece_ids - returned_logs_piece_ids
        if returned_logs.any? and unscanned_return_pieces.any?
            $LOG.debug "Order line #returned_at - not all barcodes have been scanned Returned: [line: %i, order: %i, piece(s): %s]" % [ id, order_id, unscanned_return_pieces.join(',') ]
            return
        end

        return returned_logs.first&.created_at
    end

    # TODO: Update this to use the OrderLineDetail model
    def shipped_at
        return unless product&.product_pieces
        shipped_logs = ProductPieceLocation.all(table_name: 'orders', table_id: order_id, log_type: 'Shipped', void: 'no', product_piece_id: product.product_pieces.pluck(:id), order: [ :id.asc ])
        shipped_logs_piece_ids = shipped_logs.pluck(:product_piece_id)
        all_product_piece_ids = product.product_pieces.pluck(:id)

        unscanned_shipped_pieces = all_product_piece_ids - shipped_logs_piece_ids
        if shipped_logs.any? and unscanned_shipped_pieces.any?
            $LOG.debug "Order line #shipped_at - not all barcodes have been scanned Shipped: [line: %i, order: %i, piece(s): %s]" % [ id, order_id, unscanned_shipped_pieces.join(',') ]
        end

        return shipped_logs.first&.created_at
    end

    def self.void_line_belonging_to_user(line_id, user)
        line = OrderLine.first(id: line_id, OrderLine.order.user_id => user&.id)

        unless line
            $LOG.debug "Order line belonging to user NOT voided: %i [user: %s]" % [ line_id, user.email ]
            return false
        end

        return line.void!(voided_by: user)
    end

    def void!(voided_by:)
        unless self.voidable? || voided_by.type == 'Employee'
            $LOG.debug "Order line NOT voided - not voidable: %i [user: %s, order: %i]" % [ self.id, voided_by&.email, self.order&.id ]
            return false
        end

        result = false

        $DB.transaction do
            # Void product piece locations records
            return false unless ProductPieceLocation.void_by_order_line(self.id, voided_by: voided_by)

            order = Order.first(id: self.order.id)

            # Void order line row
            self.void = 'yes'
	    self.voided_date = Time.zone.now
            self.voided_by = voided_by&.id

            if self.save && order.changed! && order.refresh_damage_waiver!
                $LOG.info "Order line voided: %i [user: %s]" % [ self.id, voided_by&.email ]
                result = self
                return true
            else
                $LOG.debug "Order line NOT voided - DB error: %i [user: %s] %s" % [ self.id, voided_by&.email, self.errors.inspect ]
                return false
            end
        end

        return result
    end

    # Verifies last barcode scan is OnOrder after checking if order is frozen
    def voidable?(at: Time.zone.now)
        return false unless order.open?
        return false unless order.rental?
        return false if order.frozen?(at: at)
        product.barcodes.each{ |bc| return false unless bc.last_scan&.log_type == 'OnOrder' } if product
        return true
    end

    # Scope for lines that are not voidable
    def self.unvoidable_lines
        all( OrderLine.order.due_date.not => nil, OrderLine.order.type => 'Rental' ) & (self.unvoidable_due_date | self.unvoidable_last_scan)
    end

    def self.unvoidable_due_date
	all( OrderLine.order.due_date.lt => VOID_THRESHOLD_DAYS.business_days.after(Time.previous_business_day(Time.zone.today)).to_date )
    end

    # NOTE: I think this is to check if the order has been picked/pulled/delivered.
    def self.unvoidable_last_scan
        all( conditions: [ "IF((SELECT COUNT(id) FROM product_piece_locations WHERE table_name = 'orders' AND table_id = `order_lines`.`order_id` AND void = 'no' AND log_status = 'Posted' GROUP BY table_id) > 0, (SELECT log_type FROM product_piece_locations WHERE table_name = 'orders' AND table_id = `order_lines`.`order_id` AND void = 'no' AND log_status = 'Posted' ORDER BY id DESC LIMIT 1), 0) != ?", 'OnOrder' ] )
    end

    # Scope for unvoided lines that represent products
    def self.product_lines
        all( :product.not => nil, conditions: [ 'LOWER(`order_lines`.`void`) = ?', 'no' ] )
    end

    def self.not_voided
        all( conditions: [ "LOWER(void) = 'no'" ] )
    end

    def self.voided
        all( conditions: [ "LOWER(void) = 'yes'" ] )
    end

    # Scope for all lines that represent products
    def self.all_product_lines
        all( :product.not => nil )
    end

    def self.non_product_lines
        all( product: nil, conditions: [ 'LOWER(void) = ?', 'no' ] )
    end

    # Scope for all lines that represent damage waiver
    def self.damage_waiver
        all( description: 'Damage Waiver' )
    end

    def self.shipped
        all( OrderLine.detail.shipped_at.not => nil )
    end

    def self.not_shipped
        all( OrderLine.detail.shipped_at => nil )
    end

    def self.returned
        all( OrderLine.detail.returned_at.not => nil )
    end

    def self.not_returned
        all( OrderLine.detail.returned_at => nil )
    end

    def self.search_description_product(query)
        return all() unless query
        return all(conditions: [ "CAST(id AS CHAR) LIKE '#{query.to_i}%'" ]) |
               all(conditions: [ "CAST(product_id AS CHAR) LIKE '#{query.to_i}%'" ]) |
               all(OrderLine.product.product.like => "%#{query}%") |
               all(:description.like => "%#{query}%")
    end

end

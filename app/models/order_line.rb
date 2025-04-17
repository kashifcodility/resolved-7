class OrderLine < ApplicationRecord
    # Constants
    VOID_THRESHOLD_DAYS = 2 # Order is voidable until X business days before scheduled delivery
  
    # Associations
    belongs_to :order
    belongs_to :product, optional: true
    belongs_to :voided_by_user, class_name: 'User', foreign_key: :voided_by, optional: true
    belongs_to :room
    belongs_to :floor
    has_many :extra_fees
    has_one :detail, class_name: 'OrderLineDetail', foreign_key: :order_line_id
    has_many :product_piece_locations
        # Validations (optional, depending on your needs)
    validates :order_id, presence: true
    validates :quantity, numericality: { greater_than: 0 }
    validates :product_id, presence: true, if: -> { product.present? }
    validates :price, numericality: true, allow_nil: true
    validates :base_price, numericality: true, allow_nil: true
    validates :voided_date, presence: true, if: -> { void == 'Yes' }  


    def self_rental_pre_credited?() self_rental_pre_credited =~ /yes/i end
    def change_confirmed?() change_confirmed =~ /yes/i end
    def void?() void =~ /yes/i end
    def tax
        price - base_price
    end
    # NOTE: Gets first product's product piece on order date
    # TODO: Update this to use the OrderLineDetail model
    def created_at(show_void: false)
        # return unless product&.product_pieces
        # filters = { table_name: 'orders', table_id: order_id, log_type: 'OnOrder', product_piece_id: product.product_pieces.pluck(:id), order: [ :id.asc ] }
        # filters[:void] = 'no' unless show_void
        # onorder_logs = ProductPieceLocation.all(filters)
        # onorder_logs_piece_ids = onorder_logs.pluck(:product_piece_id)
        # all_product_piece_ids = product.product_pieces.pluck(:id)

        # unscanned_onorder_pieces = all_product_piece_ids - onorder_logs_piece_ids
        # if onorder_logs.any? and unscanned_onorder_pieces.any?
        #     Rails.logger.debug "Order line #created_at - not all barcodes have been scanned OnOrder: [line: %i, order: %i, piece(s): %s]" % [ id, order_id, unscanned_onorder_pieces.join(',') ]
        # end

        # return onorder_logs.first&.created_at



        return unless product&.product_pieces

  # Build the base query for ProductPieceLocation
  onorder_logs_query = ProductPieceLocation.where(
    table_name: 'orders',
    table_id: order_id,
    log_type: 'OnOrder',
    product_piece_id: product.product_pieces.select(:id)
  )

  # Apply the void filter if needed
  onorder_logs_query = onorder_logs_query.where(void: 'no') unless show_void

  # Execute the query to get the result
  onorder_logs = onorder_logs_query.order(:id)

  # Get the product piece IDs for the current product
  all_product_piece_ids = product.product_pieces.select(:id)

  # Get the unscanned pieces by checking which product pieces are not in onorder_logs
  unscanned_onorder_pieces = all_product_piece_ids.where.not(id: onorder_logs.select(:product_piece_id))

  # If there are any unscanned pieces, log the message
  if onorder_logs.exists? && unscanned_onorder_pieces.exists?
    Rails.logger.debug "Order line #created_at - not all barcodes have been scanned OnOrder: [line: %i, order: %i, piece(s): %s]" % [id, order_id, unscanned_onorder_pieces.pluck(:id).join(',')]
  end

  # Return the created_at of the first onorder_log
  onorder_logs.first&.created_at
    end

    # NOTE: Gets first product's product piece return date
    # TODO: Update this to use the OrderLineDetail model
    def returned_at
        return unless product&.product_pieces
        # returned_logs = ProductPieceLocation.all(table_name: 'orders', table_id: order_id, log_type: 'Returned', void: 'no', product_piece_id: product.product_pieces.pluck(:id), order: [ :id.desc ])
        returned_logs = ProductPieceLocation
  .where(table_name: 'orders', table_id: order_id, log_type: 'Returned', void: 'no')
  .where(product_piece_id: product.product_pieces.pluck(:id))
  .order(id: :desc)
        returned_logs_piece_ids = returned_logs.pluck(:product_piece_id)
        all_product_piece_ids = product.product_pieces.pluck(:id)

        unscanned_return_pieces = all_product_piece_ids - returned_logs_piece_ids
        if returned_logs.any? and unscanned_return_pieces.any?
            Rails.logger.debug "Order line #returned_at - not all barcodes have been scanned Returned: [line: %i, order: %i, piece(s): %s]" % [ id, order_id, unscanned_return_pieces.join(',') ]
            return
        end

        return returned_logs.first&.created_at
    end

    # TODO: Update this to use the OrderLineDetail model
    def shipped_at
        return unless product&.product_pieces
        shipped_logs = ProductPieceLocation
        .where(
          table_name: 'orders',
          table_id: order_id,
          log_type: 'Shipped',
          void: 'no',
          product_piece_id: product.product_pieces.pluck(:id)
        )
        .order(id: :asc) 
        # ProductPieceLocation.all(table_name: 'orders', table_id: order_id, log_type: 'Shipped', void: 'no', product_piece_id: product.product_pieces.pluck(:id), order: [ :id.asc ])
        shipped_logs_piece_ids = shipped_logs.pluck(:product_piece_id)
        all_product_piece_ids = product.product_pieces.pluck(:id)

        unscanned_shipped_pieces = all_product_piece_ids - shipped_logs_piece_ids
        if shipped_logs.any? and unscanned_shipped_pieces.any?
            Rails.logger.debug "Order line #shipped_at - not all barcodes have been scanned Shipped: [line: %i, order: %i, piece(s): %s]" % [ id, order_id, unscanned_shipped_pieces.join(',') ]
        end

        return shipped_logs.first&.created_at
    end

    def self.void_line_belonging_to_user(line_id, user)
        line = OrderLine.first(id: line_id, OrderLine.order.user_id => user&.id)

        unless line
            Rails.logger.debug "Order line belonging to user NOT voided: %i [user: %s]" % [ line_id, user.email ]
            return false
        end

        product = line.product
        product.update(quantity: product.quantity + line.quantity)
        product_pieces = ProductPiece.all(product_id: product.id, order_line_id: line.id)  
        product_pieces.each do |pp|
          pp.update(order_line_id: 0)
          order_log = OrderLog.first(order_id: line.order.id)
          array = eval(order_log.product_pieces) if order_log.present?
        #   array.reject! { |sub_array| sub_array[0] == product&.id && sub_array[1] == line&.id }
          array.reject! { |sub_array| sub_array[0] == product&.id } if array.present?
          order_log.update(product_pieces: array) if order_log.present?
        end unless product_pieces.blank?
        if line.destroy
          
          product 
        else
           false
        end     
    end

    def void!(voided_by:)
        unless self.voidable? || voided_by.user_type == 'Employee'
            Rails.logger.debug "Order line NOT voided - not voidable: %i [user: %s, order: %i]" % [ self.id, voided_by&.email, self.order&.id ]
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
                Rails.logger.info "Order line voided: %i [user: %s]" % [ self.id, voided_by&.email ]
                result = self
                return true
            else
                Rails.logger.debug "Order line NOT voided - DB error: %i [user: %s] %s" % [ self.id, voided_by&.email, self.errors.inspect ]
                return false
            end
        end

        return result
    end

    # Verifies last barcode scan is OnOrder after checking if order is frozen
    def voidable?(at: Time.zone.now)
        # return false unless order.open?
        # return false unless order.rental?
        # return false if order.frozen?(at: at)
        # return false if order.due_date.to_date == Time.zone.yesterday # for order lock on due date before 1 day
        return false if order.status == 'Renting' || order.status == 'Destage' || order.status == 'Complete' || order.status == 'Void'  
        # product.barcodes.each{ |bc| return false unless bc.last_scan&.log_type == 'OnOrder' } if product
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
        OrderLine
                .where.not(product: nil)
                .where('LOWER(order_lines.void) = ?', 'no')
    end

    def self.not_voided
        where("LOWER(void) = ?", 'no')
      end
      
      def self.voided
        where("LOWER(void) = ?", 'yes')
      end
      
      def self.all_product_lines
        where.not(product: nil)
      end
      
      def self.non_product_lines
        where(product: nil).where("LOWER(void) = ?", 'no')
      end
      
      def self.damage_waiver
        where(description: 'Damage Waiver')
      end
      
      def self.shipped
        joins(:detail).where.not(order_lines_detail: { shipped_at: nil })
      end
      
      def self.not_shipped
        joins(:detail).where(order_lines_detail: { shipped_at: nil })
      end
      
      def self.returned
        joins(:detail).where.not(order_lines_detail: { returned_at: nil })
      end
      
      def self.not_returned
        joins(:detail).where(order_lines_detail: { returned_at: nil })
      end
      

    def self.search_description_product(query)
        return all() unless query
        return all(conditions: [ "CAST(id AS CHAR) LIKE '#{query.to_i}%'" ]) |
               all(conditions: [ "CAST(product_id AS CHAR) LIKE '#{query.to_i}%'" ]) |
               all(OrderLine.product.product.like => "%#{query}%") |
               all(:description.like => "%#{query}%")
    end

end

# require 'sdn/db'
# require 'intercom'

# Manages SDN Orders
#
# Author: Jimmy Gleason <jimmy@sdninc.net>
#
# TODO: Be thoughtful about how to abstract this class... testing and single responsibility
#
# NOTE: I'm satisfied with this methodology for raising exceptions. Log the #full_message at
#       the origin of the error and then pass it up the chain, doing DB transactions along the way.
#       It's a bit verbose those. Work on DRYing it up.
#
class Sdn::Order

    module Exceptions
        class Error < RuntimeError
            attr_reader :user_message
            def initialize(message, user_message: nil)
                super(message)
                @user_message = user_message == :message ? message : user_message || 'Unknown error.'
            end
        end
        class OrderError < Error; end
        class ProductNotRentable < OrderError; end
        class OrderOwnershipInvalid < OrderError; end
        class OrderHoldError < OrderError; end
        class SAILError < OrderError; end
        class UpdateCreditCardError < OrderError; end
    end
    include Exceptions

    attr_reader :model

    def initialize(model: nil)
        @model = model || ::Order.new
    end

    def self.from_model(model)
        return self.new(model: model)
    end

    # Adds multiple products to an order
    # products is expected to be an array of hashes: { product: [product model], price: [decimal] }
    def add_products(products, email_receipt: false, user_override: nil)
        begin
            ActiveRecord::Base.transaction do

                products.each do |product|
                    
                    add_product(product[:product], price: product[:price], email_receipt: false, user_override: user_override, product_hash: product)
                end

                ReceiptMailer.new.send_customer_add_to_order_receipt(self, products.pluck(:product)).deliver if email_receipt and products.size > 1 # not sending receipts for only 1 product

            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error creating add products.")
        end
    end

    # Adds product and all required fields to order
    # TODO: Add price adjustments for discounts/own inventory?
    # TODO: Write tests
    def add_product(product_model, price: nil, email_receipt: false, user_override: nil, product_hash: product)
        # if product_model.on_open_order?
        #     Rails.logger.debug "Item NOT added to order - exists on open order: [product: %i, user: %s]" % [ product_model.id, user&.email ]
        #     raise ProductNotRentable.new("Product is on open order.", user_message: :message) if product_model.on_open_order?
        # end                       #now product has many pieces, so need to manage by pieces.

        price ||= product_model.rent_per_month

        begin
            ActiveRecord::Base.transaction do

                create_order_line(product: product_model, base_price: price, product_hash: product_hash)
                create_product_piece_locations(product: product_model)
                # refresh_damage_waiver will calculate after discussion.
                ReceiptMailer.new.send_customer_add_to_order_receipt(self, product_model).deliver if email_receipt
                OrderEditLog.add_product(model, product_model, user: user_override || user)

            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error creating add product.")
        end    
    end

    # Creates an order line
    # TODO: Write tests
    def create_order_line(product:, base_price:, taxed: true, room_id: nil, floor_id: nil, description: nil, product_hash: p)

        begin
            ActiveRecord::Base.transaction do

                # Self rental commission
                if user.id == product.customer_id
                    base_price = (base_price * Fee.self_rental_commission).round(4).to_f rescue base_price&.to_f
                end

                discount_percentage = user&.user_group&.discount_percentage #according user group gold , diamond

                if discount_percentage.present?
                    discount_price = product_hash[:price].to_f - (product_hash[:price].to_f * discount_percentage.to_i / 100) 
                end

                line = ::OrderLine.create(
                    order_id:    order_id,
                    product_id:  product.id,
                    base_price:  product_hash[:intent] == "rent" ? product.rating_price_rent : product.rating_price_sale, #price according rating of product
                    price:       discount_price,
                    description: description,
                    line_type:   product_hash[:intent],
                    room_id:     product_hash[:room].present? ? product_hash[:room].to_i : user&.rooms&.find{ |e| e.name == "Unassigned" }&.id,
                    quantity:    product_hash[:quantity],
                    floor_id:    floor_id || Floor.first&.id,
                )

                if line.persisted?
                    product_hash[:quantity].to_i.times do
    
                        product_piece = ProductPiece.where(product_id: product.id, order_line_id: 0, status: "Available")&.first
                        if product_piece.present? && product_piece.order_line_id == 0
                            product = product_piece.product
                            product.update(quantity: product.quantity.to_i - 1) if product.present?
                            product_piece.order_line_id = line.id
                            product_piece.save
                        end
    
                    end
                    Rails.logger.info "Order line created: [line: %i, order: %i, user: %s]" % [ line.id, order_id, user.email ]
                    return line
                else
                    
                    Rails.logger.error "Order line NOT created: [order: %i, user: %s] %s" % [ order_id, user.email, line&.errors.inspect ]
                    raise OrderError.new(line.errors.inspect, user_message: "Error creating order line.")
                end

            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error creating order line.")
        end
    end

    # TODO: Write tests
    def create_product_piece_locations(product:, user_override: nil)
        begin
            ActiveRecord::Base.transaction do

                created_ppls = []
                product.product_pieces.each do |piece|
                    ppl = create_product_piece_location(piece: piece, user_override: user_override)
                    created_ppls << ppl if ppl
                end
                return created_ppls

            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error creating product piece location.")
        end
    end

    # TODO: Write tests
    def refresh_damage_waiver
        begin
            ActiveRecord::Base.transaction do
                unless model.refresh_damage_waiver!
                    raise OrderError.new("Damage waiver NOT refreshed", user_message: "Error updating order's damage waiver.")
                end

            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error creating damage waiver.")
        end
    end

    # TODO: Write tests
    def create_product_piece_location(piece:, user_override: nil)
        return if piece.void?

        begin
            ActiveRecord::Base.transaction do

                ppl = ProductPieceLocation.create(
                    product_piece: piece,
                    table_name:    'orders',
                    table_id:      order_id,
                    log_type:      'OnOrder',
                    log_status:    'Posted',
                    created_by:    user_override&.id || user.id,
                )

                if ppl.persisted?
                    Rails.logger.info "PPL created: [ppl: %i, piece: %i, product: %i, order: %i, user: %s]" % [ ppl.id, piece.id, piece.product_id, order_id, user.email ]
                    return ppl
                else
                    Rails.logger.error "PPL NOT created: [piece: %i, product: %i, order: %i, user: %s] %s" % [ piece.id, piece.product_id, order_id, user.email, ppl&.errors.inspect ]
                    raise OrderError.new(ppl&.errors.inspect, user_message: "Error putting barcode on hold.")
                end

            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error creating ppl.")
        end
    end

    # Same thing as #void, but customer business rules applied
    # email_confirmation - sends an email to the customer if successful
    # TODO: Write tests
    def cancel(email_confirmation: true)
        begin
            ActiveRecord::Base.transaction do

                # check_cancel_timeframe
                check_cancel_order_status

                void(voided_by: model.user, email_confirmation: true)

            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error canceling order.")
        end
    end

    def check_cancel_order_status
        raise OrderError.new("Order status must be 'Open' or 'Pulled' - got #{status}", user_message: "Order can not be cancelled - please contact us.") unless status.among?('Open', 'Pulled')
    end

    def check_cancel_timeframe
        if model.frozen?
            raise OrderError.new("Invalid timeframe for cancelling: [order: #{order_id}]", user_message: "Order is frozen and can't be cancelled.")
        end
    end

    # Voids an order
    # TODO: Write tests
    def void(voided_by:, email_confirmation: true)
        begin
            ActiveRecord::Base.transaction do

                if model.void?
                    Rails.logger.debug "Order has already been voided: [order: #{order_id}]"
                    raise OrderError.new("Order already voided.", user_message: :message)
                end
                # Void the order lines
                # model.order_lines.each { |ol| ol.void!(voided_by: voided_by) }
                model.order_lines.each do |ol| 
                    product = ol.product
                    product.update(quantity: product.quantity + ol.quantity)
                    product_pieces = ProductPiece.all(product_id: product.id, order_line_id: ol.id)  
                    product_pieces.each do |pp|
                      pp.update(order_line_id: 0)
                    end unless product_pieces.blank?
                    
                    ol.update(voided_by: voided_by&.id, void: 'yes', voided_date: Time.zone.now)  
                end
                # Change order status to void
                model.status = 'Void'
                Rails.logger.info "Order voided: [order: %i, voided by: %s, user: %s]" % [ order_id, voided_by&.email, user.email ] if model.save

                if email_confirmation
                    ReceiptMailer.new.send_customer_cancellation_confirmation(self).deliver
                    # ReceiptMailer.new.send_admin_cancellation_confirmation(self, voided_by).deliver
                end

                return true

            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error in voiding order.")
        end
    end

    # Requests destage
    def request_destage(date:, service: 'destage', expedited: false, requested_by:, email_confirmation: true, arrivy_task: true)
        begin
            ActiveRecord::Base.transaction do
                date = date.to_date
                raise OrderError.new("Invalid date, please select date at least 7 days out.", user_message: :message) unless model.can_be_destaged?(date: date)

                siblings = model.sibling_rental_orders

                to_update = [ model ] + siblings
                to_update.each do |o|
                    o.destage_date = date
                    o.status = "Destage"
                    if o.save
                        Rails.logger.info "Destage date set for order: [order: %i, date: %s]" % [ order_id, date ]
                    else
                        Rails.logger.error "Destage date NOT set for order: [order: %i, date: %s] %s" [ order_id, date, o.errors.inspect ]
                        raise OrderError.new("Couldn't set destage date for order #{order_id}", user_message: :message)
                    end
                end

                # create_arrivy_destage_task(service) if arrivy_task
                # create_intercom_destage_event(service: service, requested_by: requested_by, date: date, expedited: expedited)

                if email_confirmation
                    ReceiptMailer.new.send_destage_request(order: self, date: date, requested_by: requested_by, expedited: expedited, siblings: siblings).deliver
                end

                return true
            end
        rescue Exception => error
            raise OrderError.new(error.message, user_message: "Error in destaging order.")
        end
    end

    # Sends event to intercom
    def create_intercom_destage_event(service:, requested_by:, date:, expedited: false)
        # TODO: Move token to config
        intercom = Intercom::Client.new(token: '')
        event = {
                event_name:          'destage-request',
                email:               requested_by&.email,
                created_at:          Time.zone.now.to_i,
                metadata:            {
                    first_name:          requested_by&.first_name,
                    last_name:           requested_by&.last_name,
                    appointment_type:    service == 'destage_dropoff' ? 'Drop-Off' : 'Destage',
                    requested_date:      date&.strftime('%m/%d/%Y'),
                    project_name:        model&.project_name,
                    appointment_address: model&.shipping_address&.full_address,
                    order:               model&.id,
                    expedited_destage_request: expedited ? "Expedited Destage Request" : '',
                }
        }
        intercom.events.create(event)
    end

    # Updates credit card assigned to order
    #  - ownership_check  makes sure supplied card model belongs to order owner
    def update_credit_card(card_model, ownership_check: true)
        if ownership_check && card_model.user_id != user.id
            Rails.logger.debug "Credit card does NOT belong to order owner: [card owner: %i, order owner: %i]" % [ card_model.user_id, user.id ]
            raise UpdateCreditCardError.new("Card and order do not have the same owner.", user_message: :message)
        end

        model.credit_card_id = card_model.id
        model.save
    end

    # Toggles hold on/off
    def toggle_hold(onoff, employee:)
        begin
            raise OrderHoldError.new("Hold action must be 'on' or 'off'.", user_message: :message) unless onoff.among?('on', 'off')
            raise OrderHoldError.new("Invalid user for holding.", user_message: :message) unless employee&.user_type.capitalize == 'Employee'

            ActiveRecord::Base.transaction do

                hold = model.hold || ::OrderHold.new(order_id: order_id, created_by: employee.id, on_hold: nil)
                old_state = hold.on_hold
                new_state = onoff == 'on' ? 'HOLD' : 'CHARGE'

                hold.on_hold = new_state
                hold.updated_by = employee.id

                if hold.save
                    Rails.logger.info "Order hold toggled: [hold: %i, order: %i, hold: %s, user: %s]" % [ hold.id, order_id, new_state, employee&.email ]
                else
                    Rails.logger.error "Order hold NOT toggled: [hold: %s, order: %i, hold: %s, user: %s] %s" % [ hold.id, order_id, new_state, employee&.email, hold.errors.inspect ]
                    raise OrderHoldError.new("Error saving hold state.", user_message: :message)
                end

                OrderEditLog.create(
                    order_id:  order_id,
                    user_id:   employee.id,
                    action:    'toggle_hold',
                    old_value: old_state,
                    new_value: new_state,
                )

                return true

            end
        rescue Exception => error
            raise error
        rescue => error
            Rails.logger.error "Order hold NOT toggled - rolled back: [order: %i, action: %s, user: %s] %s" % [ order_id, onoff, employee&.email, error.full_message ]
            raise OrderHoldError.new(error.message, user_message: "Unable to update hold.")
        end
    end


    #
    # Helpers
    #

    # TODO: Write tests
    def with_added_tax(price)
        price = price&.to_f
        (price + (price * tax_rate))&.round(4).to_f
        # (price&.to_f + (price&.to_f * tax_rate))&.round(4).to_f
    end

    # TODO: Write tests
    def tax_rate
        begin
            return model&.tax_authority&.total_rate.to_f
        rescue => error
            Rails.logger.debug "Order tax rate not found: [order: %i] %s" % [ order_id, error.full_message ]
            return 0
        end
    end

    # TODO: Write tests
    def order_id
        @order_id ||= model.id
    end

    # TODO: Can an order not have a user?
    # TODO: Write tests
    def user
        @user ||= model.user
    end

    def status
        model.status
    end

end

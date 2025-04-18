# require 'active_merchant'
# require 'sdn/card'


require 'json'

require 'stripe'
# Sdn Cart/Checkout Library
#
#
# TODO: Implement better exception throwing
# TODO: Abstract different functionality to different calsses (cart, checkout, orders, payment)?
# TODO: Standardize log formatting
# TODO: Standardize hash keys (WRT JSON)... symbolize when reading and stringify when writing
# TODO: If payment method is changed, remove any associated `checkout` data for previous payment method.
#       Not a huge deal since everything keys off `payment_method` value, but should be cleaned up.
# TODO: A lot of the logic in this class should be in the model.
#
class Sdn::Cart

    module Exceptions
        class Error             < RuntimeError;  end
        class CartError         < Error;         end
        class OrderError        < CartError;     end
        class OrderLineError    < OrderError;    end
        class ProductPieceError < OrderError;    end
        class SAILError         < Error;         end
        # NOTE: This follows the bad convention I started with the Card class. I've learned the limitations
        #       of using exceptions for non-exceptional cases. This needs to be refactored.
        class PaymentError < Error
            attr_reader :user_message
            def initialize(message, user_message: nil)
                super(message)
                @user_message = user_message == :message ? message : user_message || 'Unknown error.'
            end
        end
        class ChargeAccountError < PaymentError; end
        class CreditCardError < PaymentError; end
        class TransactionError < Error; end
    end
    include Exceptions

    # const_def :CARD_AUTH_AMOUNT, 0.01

    # Load/create the cart model
    # Should this class be decoupled from a user?
    def initialize(user)
        @user = user
        @user.cart ||= ::Cart.new

        if @user.cart.id.nil?
            Rails.logger.debug "CART: New cart initialized for %s" % [@user.email]
            @user.cart.save
        end

        @cart_model = @user.cart

        Rails.logger.debug "CART: Existing cart loaded for %s" % [@user.email]
    end

    # Adds item to cart
    def add_item(product, intent,room_id, quantity, remaining_quantity)
        raise CartError.new "Must buy or rent product." unless ['rent', 'buy'].include?(intent) 
        raise CartError.new "Invalid product." unless product.is_a?(Product)
        raise CartError.new "Item quantity not available." if @cart_model.item_in_cart?(product) 
        # && @cart_model.item_quantity_remaining?(quantity, remaining_quantity, product&.id)
        raise CartError.new "Item already reserved." if product.is_reserved?
        raise CartError.new "Can't buy this item." if (intent == "buy" && !product.is_buyable?)
        raise CartError.new "Can't rent this item." if (intent == "rent" && !product.is_rentable?)
        # raise CartError.new "Item already on an open order." if product.on_open_order?

        ActiveRecord::Base.transaction do
            # Add item to cart
            self_rental_commission = (intent == 'rent' && @user.id == product.customer_id) # Is user renting their own product?
            @cart_model.add_item(product, intent, room_id, quantity, self_rental_commission)
            @cart_model.save
            Rails.logger.info "CART: Product %i saved to %s's cart (%s)." % [product.id, @user.email, intent]

            # Reserve item (only allowed to exist in one cart at a time)
            # product.reserve!(@user.id)
        end
    end

    def items(); @cart_model.get_items; end
    def has_rent_items?(); @cart_model.has_rent_items?; end
    def has_buy_items?(); @cart_model.has_buy_items?; end

    # Returns items grouped by site
    def items_by_site
        cart_items = @cart_model.get_items
        sites = Site.where(id: cart_items.pluck(:site_id))
        return @items_by_site = sites.map do |site|
            OpenStruct.new(
                id:     site.id,
                name:   site.site,
                region: site.region,
                items:  cart_items.select { |item| item[:site_id] == site.id }
            )
        end
    end

    # Are there items across multiple regions?
    def items_in_multiple_regions?
        return items_by_site.group_by{ |e| e.region }.size > 1
    end

    # Remove item(s) from a cart
    # Destroys the cart model if ids == * (after removing reservations)
    # Destroys cart model if last item is removed
    # TODO: Add integrity checks around removing reservations
    def remove_items(ids)
        # ids = @cart_model.items.pluck("uniq_id") if ids == "*" # get all the ids
        
        ids = eval(@cart_model.items).pluck(:id) 
        reservations = ProductReservation.where(product_id: ids, user_id: @user.id)

        Array(ids).each do |id|
            # Destroy the item in the cart
            if @cart_model.destroy_item!(id)
                Rails.logger.info "CART: Product %i removed from %s's cart." % [id, @user.email]
            else
                Rails.logger.error "CART: Product %i not found in %s's cart. Not removed. | %s" % [id, @user.email, @cart_model.errors.inspect]
            end

            # Destroy the reservation
            if reservation = reservations.find{ |i| i.product_id == id.to_i }
                if reservation.destroy!
                    Rails.logger.info "CART: Reservation of product %i for %s (ID %i) destroyed." % [id, @user.email, @user.id]
                else
                    Rails.logger.error "CART: Reservation of product %i for %s (ID %i) NOT destroyed. | %s" % [id, @user.email, @user.id, reservations&.errors.inspect]
                end
            else
                Rails.logger.error "CART: Reservation of product %i for %s (ID %i) doesn't exist." % [id, @user.email, @user.id]
            end
        end

        @cart_model.destroy! if @cart_model.items.empty?
    end

    

    def items_sub_total_and_quantity
        sub_total = 0.0
        total_quantity = 0
        cart_items = eval(@cart_model.items)
        cart_items.each do |item|
           sub_total = sub_total + (item[:price].to_f * item[:quantity].to_i)
           total_quantity += item[:quantity].to_i
        end  if self.items.present?
        [sub_total, total_quantity]
    end

    def clear!
        self.remove_items('*')
    end

    def subtotal(site_id=nil)
        subtotal_by_intent('buy', site_id) + subtotal_by_intent('rent', site_id)
    end

    # Get subtotal by intent
    # NOTE: Rounding the subtotal to a precision of two decimals will be inaccurate at
    #       scale. Ideally, the database should have a precision of 3 for money fields.
    def subtotal_by_intent(intent, site_id=nil)
        all_rent_items = items.select { |i| i[:intent] == intent }
        if site_id
            subtotal = all_rent_items.select { |i| i[:site_id] == site_id }.pluck(:price).map(&:to_d).sum || 0
        else
            subtotal = all_rent_items.pluck(:price).map(&:to_d).sum || 0
        end
        return subtotal.to_d.ceil(2)
    end

    def total(site_id=nil)
        total_by_intent('buy', site_id) + total_by_intent('rent', site_id)
    end

    def total_by_intent(intent, site_id=nil)
        subtotal = subtotal_by_intent(intent, site_id)
        total = subtotal
        total = subtotal + tax_by_intent(intent, site_id) unless @user.tax_exempt?
        total = total + damage_waiver_by_intent(intent, site_id) unless @user.damage_waiver_exempt? # Damage waiver not taxed
        return total
    end

    def tax(site_id=nil)
        tax_by_intent('buy', site_id) + tax_by_intent('rent', site_id)
    end

    # NOTE: Rounding the tax to a precision of two decimals will be inaccurate at
    #       scale. Ideally, the database should have a precision of 3 for money fields.
    def tax_by_intent(intent, site_id=nil)
        return 0.00.to_d if @user.tax_exempt?
        (subtotal_by_intent(intent, site_id) * tax_rate).to_d.ceil(2)
    end

    def damage_waiver(site_id=nil)
        damage_waiver_by_intent('rent', site_id)
    end


    # NOTE: Rounding the waiver amount to a precision of two decimals will be inaccurate at
    # scale. Ideally, the database should have a precision of 3 for money fields.
    def damage_waiver_by_intent(intent, site_id=nil)
        return 0.00.to_d if intent == 'buy' or @user.damage_waiver_exempt? # Damage waiver only applies to rental items
        (subtotal_by_intent(intent, site_id) * Fee.damage_waiver).to_d.ceil(2)
    end

    # TODO: Throw exception if tax_rate is unavailable
    def tax_rate
        (checkout_data['tax_rate'] || 0).to_d rescue 0
    end

    # Calculate the shipping cost based
    #
    # Currently this is manually charged in WH2 upon delivery, so
    # this function is to display a shipping estimate only. Charged
    # per order type per warehouse/site.
    #
    # Includes `:lines` key to explain how the number was calculated.
    #
    # TODO: These values should be in a config
    def shipping
        shipping = {}
        shipping[:total] = 0.to_d
        shipping[:lines] = []

        items.group_by{ |i| i[:site_id] }.each do |site_id, items_by_site|
            subtotal_buy = subtotal_by_intent('buy', site_id)
            subtotal_rent = subtotal_by_intent('rent', site_id)
            if subtotal_buy > 0 && subtotal_by_intent('buy', site_id) < 3000 && subtotal_rent == 0
                shipping[:total] = shipping[:total] + 169
                shipping[:lines] << [169, 'buy', site_id, 'Less than $3000 sale']
            end


            if subtotal_rent > 0
                if subtotal_rent < 500
                    shipping[:total] = shipping[:total] + 119
                    shipping[:lines] << [119, 'rent', site_id, 'Less than $500 rental']
                elsif subtotal_rent < 1000
                    shipping[:total] = shipping[:total] + 169
                    shipping[:lines] << [169, 'rent', site_id, 'Less than $1000 rental']
                end
            end
        end

        shipping[:total] = shipping[:total] + (shipping[:total] * tax_rate) unless @user.tax_exempt?

        return shipping
    end

    # Fills/updates checkout with state
    # Ran on submission of each checkout step to save progress
    def fill_checkout(params, section_name=nil)
        binding.pry
        checkout ||= {}
        checkout[section_name] ||= {} if section_name

        params.deep_stringify_keys!.each do |key, val|
            if section_name
                checkout[section_name][key] = val
            else
                checkout[key] = val
            end
        end
        @cart_model.checkout&.deep_stringify_keys!&.deep_merge!(checkout)
        @cart_model.save

        if @cart_model.persisted?
            Rails.logger.info "Saved checkout state for cart %i (user %s)." % [@cart_model.id, @user.email]
            return true
        else
            Rails.logger.error "Error updating checkout state for cart %i (user %s). | %s" % [@cart_model.id, @user.email, @cart_model.errors.inspect]
            return false
        end
    end

    # Get checkout data
    def checkout_data(section_name=nil)
        # ddddddddddd
        data = @cart_model.checkout.present? ? eval(@cart_model.checkout) : {}
        # data['billing'] ||= {}
        # data['delivery'] ||= {}
        filtered_data = section_name == 'shipping' ? data[:shipping] : data[:billing]
        if filtered_data.present?
            filtered_data.with_indifferent_access 
        else
            {}.with_indifferent_access
        end    
        
    end

    def billing_data()   checkout_data('billing');   end
    def delivery_data()  checkout_data('shipping');  end
    def shipping_data()  delivery_data();  end

    # Calculates the tax and tax location
    # 1) Assembles avatax transaction lines & gets transaction from AvaTax
    # 2) Creates new TaxAuthority record
    # 3) Saves TaxAuthority ID and tax location code to cart's `checkout`
    # TODO: Add exceptions and integrity checking
    def calculate_tax(address) # need to handle or may not be due to using stripe
        avatax_transaction = $AVALARA.create_transaction(items, address)

        tax_authority = $AVALARA.fill_tax_authority_model_with_transaction_response(avatax_transaction, TaxAuthority.new)
        tax_authority[:created_with] = 'CartReceipt'
        tax_authority[:updated_with] = 'CartReceipt'
        tax_authority.save

        tax_location_code = $AVALARA.get_location_code_from_transaction_response(avatax_transaction)

        if fill_checkout({
            tax_authority: tax_authority&.id,
            tax_loc_code:  tax_location_code,
            tax_rate:      tax_authority.total_rate,
            refresh_taxes: false,
        })
            Rails.logger.info "Cart %i checkout updated with: authority %i | loc code %s" % [@cart_model&.id, tax_authority&.id, tax_location_code]
        else
            Rails.logger.error "Error updating cart %i checkout with tax info: authority %i | loc code %s | %s" % [@cart_model&.id, tax_authority&.id, tax_location_code, @cart_model.errors.inspect]
        end
    end

    # Sets the `refresh_taxes` flag so taxes will be recalculated
    def set_refresh_taxes_flag
        if fill_checkout({ refresh_taxes: true })
            Rails.logger.info "Tax refresh flagged for cart %i (user %s)." % [@cart_model.id, @user.email]
        else
            Rails.logger.error "Error setting tax refresh flag for cart %i (user %s). | %s" % [@cart_model.id, @user.email, @cart_model.errors.inspect]
        end
    end

    # Charge the cart and convert it into an order
    # TODO: This needs to be cleaned up and refactored - hacked together for launch
    def process(data = {})
        totals = OpenStruct.new(
            subtotal_rent: self.subtotal_by_intent('rent'),
            subtotal_buy:  self.subtotal_by_intent('buy'),
            total_rent:    self.total_by_intent('rent'),
            total_buy:     self.total_by_intent('buy'),
            tax_rent:      self.tax_by_intent('rent'),
            tax_buy:       self.tax_by_intent('buy'),
            subtotal:      self.subtotal,
            damage_waiver: self.damage_waiver,
            tax:           self.tax,
            total:         self.total,
            shipping:      self.shipping
        )
        user = @user.owner.present? ? @user.owner : @user
        # Always save CC and make it visible if user wants to "save for future use"
        if billing_data['payment_method'] == 'new' # now card is added from profile of user.
            # begin
            #     d = billing_data.merge(delivery_data)
            #     cc_name = d['cc_name'].split(' ')
            #     card = ::Sdn::Card.new(@user).from_hash({
            #         token:      d['token'],
            #         pn_ref:     d['pn_ref'],
            #         card_type:  d['card_type'],
            #         last_four:  d['last_four'],
            #         exp_month:  d['cc_expiration_year'],
            #         exp_year:   d['cc_expiration_year'],
            #         label:      d['label'],
            #         first_name: cc_name[0],
            #         last_name:  cc_name[1..].join(' '),
            #         address1:   d['new_card_address1'],
            #         city:       d['new_card_city'],
            #         state:      d['new_card_state'],
            #         zipcode:    d['new_card_zipcode'],
            #     }) # FIXME: billing_data and delivery_data are a clusterfuck
            #     card_model = card.to_model
            #     card_model.visible = !!billing_data['cc_save']

            #     if card_model.save
            #         @card_to_charge = ::Sdn::Card.new(@user).from_model(card_model)
            #         Rails.logger.info "Credit card created: %i [last 4: %s, user: %s]" % [card_model.id, card_model.last_four, @user.email]
            #     else
            #         Rails.logger.error "Credit card NOT created: [last 4:: %s, user: %s] %s" % [card_model.last_four, @user.email, card_model.errors.inspect]
            #     end
            # rescue => error
            #     Rails.logger.error "Credit card NOT created: [user: %s] %s" % [@user.email, error.full_message]
            #     raise error
            # end
        elsif billing_data['payment_method'] != 'charge_account'
            # @card_to_charge = ::Sdn::Card.new(@user).from_model(CreditCard.where(user: @user, id: billing_data['payment_method']))
            # unless @card_to_charge
            #     Rails.logger.debug "Invalid credit card selected"
            #     raise CreditCardError.new('Invalid credit card selected')
            # end
        end

        orders = self.create_orders(data)
        types = orders.processed.pluck(:order_type).uniq.map(&:downcase)

        receipt = OpenStruct.new(orders: orders, totals: totals, card: nil, order_types: types)

        # Send email receipt
        ReceiptMailer.new.send_customer_order_receipt(user, receipt).deliver if orders.processed.any? rescue puts "-------------Email generation issue--------------------"

        return receipt
    end

    # Validates the supplied payment method in the checkout data
    # TODO: Raise exceptions instead of boolean
    # TODO: Move to ChargeAccount model
    def verify_charge_account(account_number)
        is_valid = ChargeAccount.first(account_number: account_number)&.belongs_to_user?(@user)

        if is_valid
            Rails.logger.info "Charge account %i is being used by user %s." % [account_number.to_i, @user.email]
            return true
        else
            Rails.logger.error "Invalid charge account %i for user %s." % [account_number.to_i, @user.email]
            return false
        end
    end

    # Authorizes card and tokenizes it
    # TODO: Save the token to user profile
    # TODO: Raise exceptions instead of boolean
    # NOTE: CC name is split so that "Joe Albert Fuckhead III" is: first=Joe; last=Albert Fuckhead III
    def verify_and_tokenize_card(cc)
        card = ::Sdn::Card.new(@user).from_new_details(
            name:         cc['cc_name'],
            number:       cc['cc_number'],
            verification: cc['cc_verification'],
            exp_month:    cc['cc_expiration_month'],
            exp_year:     cc['cc_expiration_year'],
            label:        cc['cc_label'],
            address1:     billing_data['new_card_address1'],
            address2:     billing_data['new_card_address2'], # NOTE: No longer supplied - always nil
            city:         billing_data['new_card_city'],
            state:        billing_data['new_card_state'],
            zip:          billing_data['new_card_zipcode'],
        )

        fill_checkout(card.to_hash, 'billing')
    end

    # Verify saved card belongs to user and hasn't expired
    # TODO: Add exceptions
    def verify_and_load_saved_card(card_id)
        begin
            card = ::Sdn::Card.new(@user).from_model(CreditCard.where(id: card_id, user: @user)&.first)
        rescue ::Sdn::Card::DetailsError => error
            Rails.logger.error error.message
            raise error
        end

        fill_checkout(card.to_hash, 'billing')
    end

    # Splits orders by site/intent, charges them, and creates them
    #
    # An order/transaction is created for each site, and type (buy/rent).
    # Example (3 total orders created):
    #  1 buy item in cart for Everett
    #  1 rent item in cart for Everett
    #  2 rent items in cart for Kirkland
    #
    # Once orders are split by location and intent, each new order is created and
    # individually charged. If any exceptions are thrown during this process, the
    # order is rolled back. There is the possible potential for extreme edge cases
    # where a user is billed before an exception is thrown, in which case they
    # would be charged and not have a valid order. This needs to be verified and
    # have tests written around it.
    #
    # TODO: Add reasons for failure
    # TODO: Add API calls reverting a payleap charge and/or an arrivy call, if
    #       exceptions are raised and the order is rolled back after the calls.
    def create_orders(data = {})
        @billing_address_model = @card_to_charge&.model&.address || @user.billing_address
    
        @delivery_address_model = create_order_address('delivery')

        orders = OpenStruct.new( processed: [], failed: [], charges: [] )

        items.group_by { |i| i[:site_id] }.each do |site_id, items_by_site|
            items_by_site.group_by { |j| j[:intent0] }.each do |intent, items_by_intent| # this is for buy/rent in same order
                # begin
                ActiveRecord::Base.transaction do |t|
                        order = create_order_with_stripe_invoice(items_by_intent, intent, site_id, data)
                        # orders.charges << charge_order(order, intent, site_id) #its for payleap gateway
                        # create_arrivy_task(order, intent: intent, site_id: site_id)
                        
                        # remove_items(items_by_intent.pluck(:id)) #this line replace with line below
                        @cart_model.update(items: {})    
                        orders.processed << order
                end
                # rescue => error
                #     reason = error.user_message rescue 'Unknown'
                #     product_ids = items_by_intent.pluck(:id).join(',') rescue ""

                #     Rails.logger.error "Error creating/charging an order (order creation rolled back): [reason: %s, user: %s, site: %i, intent: %s, products: %s] %s" % [ reason, @user.email, site_id, intent, product_ids, error.message ]
                #     orders.failed << {
                #         items: items_by_intent,
                #         intent: intent,
                #         site_id: site_id,
                #         reason: reason,
                #     }
                # end
            end
        end

        return orders
    end

    # Handle payment processing of order
    # Assumed that payments have been validated before getting here.
    # TODO: Add exceptions
    def charge_order(order, intent, site_id)
        receipt = OpenStruct.new(success?: false, amount: total, type: nil, order_id: order.id)

        # User is using a charge account
        if billing_data['payment_method'] == 'charge_account'
            cac = ChargeAccountCharge.create(
                charge_account_id: ChargeAccount.first(account_number: billing_data['charge_account'], user: @user).id,
                type: intent == 'buy' ? 'Online Sale' : 'Online Rental',
                status: 'Charged',
                amount: total,
                table_name: 'orders',
                table_id: order.id,
                created_by: @user.id,
                created_with: 'CartReceipt',
                updated_by: @user.id,
                updated_with: 'CartReceipt',
            )

            if cac.persisted?
                Rails.logger.info "Charge account charge created: [charge id: %i, amount: %.2f, order: %i, user: %s]" % [cac.id, total, order.id, @user.email]
                receipt[:success?] = true
                receipt[:type] = 'charge'
                return receipt
            else
                Rails.logger.error "Charge account charge NOT created: [amount: %.2f, order: %i, user: %s] %s" % [amount, order.id, @user.email, cac.errors.inspect]
                raise ChargeAccountError, cac.errors.inspect
            end
        end

        # Charge the user's credit card and add transaction record
        begin
            card = @card_to_charge

            if intent == 'rent'
                receipt = @rent_authorize_receipt || card.authorize!(0.01) # Limits auth charges to a single charge if multiple rental orders
                @rent_authorize_receipt = receipt
            else
                receipt = card.charge!(total_by_intent(intent, site_id))
            end

            if receipt.success?
                Rails.logger.info "Credit card charged: [amount: %.2f, token: %s, order: %i, intent: %s, site: %i, user: %s, receipt: %s]" % [total, billing_data['token'], order.id, intent, site_id, @user.email, receipt.inspect]
            end
        rescue => error
            Rails.logger.error "Credit card NOT charged: [amount: %.2f, token: %s, order: %i, intent: %s, site: %i, user: %s] %s" % [total, billing_data['token'], order.id, intent, site_id, @user.email, error.full_message]
            raise CreditCardError.new(error.message, user_message: (error&.user_message rescue 'Unknown error'))
        else
            # NOTE: This is where a user can be charged and an order creation can be rolled back.
            #       If creating a transaction record produces any kind of error after the user
            #       has been successfully charged, the order is not created, but they are charged.
            #       See #create_orders for why this is. It will be an extreme edge case. We should
            #       either figure out how to fix this or rescue this error and alert appropriately.
            transaction = Transaction.create(
                response:           'Processed',
                table_name:         'orders',
                table_id:           order.id,
                amount:             receipt.amount,
                tax:                tax_by_intent(intent, site_id),
                type:               'Credit Card',
                cc_last_four:       receipt.last_four,
                transaction_number: receipt.pn_ref,
                authorization_code: receipt.auth_code,
                processed_by:       @user.id,
                processed_with:     'CartReceipt',
                stored_card_id:     card.model&.id,
            )

            if transaction.persisted?
                Rails.logger.info "Transaction record created: %i [amount: %.2f, order: %i, user: %s, stored card: %s]" % [transaction.id, receipt.amount, order.id, @user.email, card.model&.id.to_s || 'N/A']
            else
                Rails.logger.error "Transaction record NOT created: [amount: %.2f, order: %i, user: %s, stored card: %s] %s" % [receipt.amount, order.id, @user.email, card.model&.id.to_s || 'N/A', transaction.errors.inspect]
                raise TransactionError, transaction.errors.inspect
            end

            # Assign card to order
            unless billing_data['payment_method'] == 'charge_account'
                order.credit_card_id = @card_to_charge.model.id
                if order.save
                    Rails.logger.info "Card saved to order: [card: %i, order: %i]" % [ @card_to_charge.model.id, order.id ]
                else
                    Rails.logger.error "Card NOT saved to order: [card: %i, order: %i] %s" % [ @card_to_charge.model.id, order.id, order.errors.inspect ]
                end
            end
        end

        receipt[:order_id] = order.id
        return receipt
    end

    def dollars_to_cents(dollars)
        (dollars * 100)
    end

    # Creates and returns order address model
    # type = 'delivery' || 'billing'
    def create_order_address(type)
        raise ArgumentError.new("Invalid address type.") unless (type == 'delivery' || type == 'billing')
        is_billing = type == 'billing'
        billing = checkout_data('billing')
        delivery = checkout_data('shipping')

        address = Address.new(
            company:      @user.company_name,
            name:         billing['shipping_contact_name'],
            address1:     is_billing ? billing['address1'] : delivery['shipping_address'],
            address2:     is_billing ? billing['address2'] : nil,
            city:         is_billing ? billing['city'] : delivery['shipping_city'],
            state:        is_billing ? billing['state'] : delivery['shipping_state'],
            zipcode:      is_billing ? billing['zipcode'] : delivery['shipping_zipcode'],
            phone:        billing['shipping_contact_phone'],
            mobile_phone: billing['shipping_mobile_phone'],
        )

        address[:table_name] = 'orders'

        address.save

        if address.persisted?
            Rails.logger.info "Address (%s) %i saved for %s." % [type, address.id, @user.email]
        else
            Rails.logger.error "Address (%s) NOT saved for %s. | %s" % [type, @user.email, address.errors.inspect]
        end

        return address
    end

    # Creates single order by intent and location
    # TODO: Add support for adding to existing order
    def create_order_with_stripe_invoice(order_items, intent, site_id, data = {})
        user = @user.owner.present? ? @user.owner : @user
        type = intent == 'buy' ? 'Sales' : 'Rental'
        Rails.logger.info "Order creation initialized: [user: %s, cart: %i, type: %s, site: %i, items: %s]" % [user.email, @cart_model.id, type, site_id, order_items]

        # Confirm all items are from the supplied site_id
        items_site_ids = order_items.pluck(:site_id).uniq
        raise ArgumentError.new "Order items must match supplied site ID." unless (items_site_ids.size == 1 && items_site_ids.first == site_id)

        billing = checkout_data('billing')
        delivery = checkout_data('delivery')

        # TODO: Attach promo codes?

        shipping_date = billing['shipping_method'] == 'delivery' ? billing['delivery_date'] : billing['pickup_date']
        pickup_time = billing['pickup_time'] || '00:00:00'
        
        due_date = DateTime.strptime("#{shipping_date} #{pickup_time}", "%m-%d-%Y %H:%M")

        # Create the order
        order = Order.new(
            user:             @user,
            site_id:          site_id,
            order_type:       type,
            rush_order:       billing['rush_order'].to_i,
            status:           'Open',
            delivery_special_considerations:  billing['delivery_special_considerations'],
            dwelling:         billing['delivery_home_type'],
            parking:          billing['delivery_parking'],
            levels:           billing['delivery_levels'],
            project_name:     billing['project_name'],
            address:          @delivery_address_model,
            billing_address:  @billing_address_model,
            # tax_authority_id: checkout_data['tax_authority'],  may be need to set in future
             # tax_location_id:  checkout_data['tax_loc_code'],
            due_date:         due_date,
            ordered_date:     Time.zone.now,
            note:             "<table width='100%'><tr><td><b>Type of Dwelling:</b></td><td style='padding-left:40px'>#{(billing[:dwelling_type] || billing[:dwelling_other])}</td></tr><tr><td><b>Easily Accessed Parking:</b></td><td style='padding-left:40px'>#{billing[:parking]}</td></tr><tr><td><b>Number of Levels:</b></td><td style='padding-left:40px'>#{billing[:levels]}</td></tr></table>".html_safe,
            service:          billing['shipping_method'] == 'delivery' ? 'Company' : 'Self',
        )
        

        if order.save
            Rails.logger.info "Order created [id: %i, type: %s, user: %s]" % [order.id, type, user.email]
        else
            Rails.logger.error "Order not created [type: %s, user: %s] %s" % [type, user.email, order.errors.inspect]
            raise OrderError, order.errors.inspect
        end
        create_order_lines_with_stripe_items(order, order_items, data, intent: intent, site_id: site_id, discount_percentage: @user&.user_group&.discount_percentage) #discount_percentage of owner that is @user
        
        
        # create_product_piece_locations(order, order_items)
        # create_ihs_catalog(order) if intent == 'rent' # no need currently, may be in future 

        return order
    end

    # Creates an order's order lines
    # TODO: Accomodate Showroom sales? (payment.php line 511)
    def create_order_lines_with_stripe_items(order, order_items, data = {}, intent:, site_id:, discount_percentage: )  
        user = @user.owner.present? ? @user.owner : @user
        # customer = Stripe::Customer.retrieve(shipping_data['stripe_id'])
        order_items.each do |order_item|
            item = order_item.with_indifferent_access
            if discount_percentage.present?
                discount = item[:price].to_f - (item[:price].to_f * discount_percentage.to_i / 100) 
            end    
            
            ol = OrderLine.create(
                product_id:  item[:id],
                base_price:  item[:price],
                order_id:    order.id,
                quantity:    item[:quantity],
                price:       discount || (item[:price].to_d * (1 + tax_rate)).round(4).to_f,
                description: intent == 'buy' ? 'Resale' : nil,
                line_type:   item[:intent],
                room_id:     item[:room_id].present? ? item[:room_id].to_i : 20,
                floor_id:    Floor.first&.id,
            )

            OrderLineDetail.create(order_line_id: ol.id, ordered_at: Time.now)
            
            if ol.present?
                item[:quantity].to_i.times do

                    product_piece = ProductPiece.where(product_id: item[:id], order_line_id: 0, status: "Available")&.first
                    if product_piece.present? && product_piece.order_line_id == 0
                        product = product_piece.product
                        product.update(quantity: product.quantity.to_i - 1) if product.present?
                        product_piece.order_line_id = ol.id
                        product_piece.save
                    end

                end
            end


            #Create an invoice item fee for each line item
            
            # Stripe::InvoiceItem.create({
            #     customer: customer.id,
            #     amount: dollars_to_cents(item[:price].to_f).to_i,
            #     currency: 'usd',
            #     description: item['id']
            # })

        end

        # shipped_fee_total = (billing_data['shipping_method'] == "pickup" ? 0.0 : Order.default_shipping_fee) + (order.rush_order == true ? Order.default_rush_order_fee : 0.0)
        # Create an invoice item for the shipping fee

        # Stripe::InvoiceItem.create({
        #     customer: customer.id,
        #     amount: dollars_to_cents(shipped_fee_total).to_i,
        #     currency: 'usd',
        #     description: 'Shipping Fee'
        # })

        # invoice = Stripe::Invoice.create({
        #     customer: customer.id,
        #     auto_advance: true # Automatically finalize the invoice
        #   })


        if order.save
            Rails.logger.info "Order lines created [lines: %s, order: %i, intent: %s, user: %s]" % [order.order_lines.pluck(:id).join('/'), order.id, intent, @user.email]
        else
            Rails.logger.error "Order lines NOT created [order: %i, intent: %s, user: %s] %s" % [order.id, intent, user.email, order.errors.inspect]
            raise OrderLineError, order.errors.inspect
        end

        # Adds damage waiver order line // below code just enter one blank entery without product into line item table. i'm commenting it.
        # unless @user.damage_waiver_exempt? || intent == 'buy'
        #     waiver_amount = damage_waiver_by_intent(intent, site_id)
        #     dw_line = OrderLine.create(
        #         order: order,
        #         base_price: waiver_amount,
        #         price: waiver_amount,
        #         description: 'Damage Waiver',
        #     )

        #     if dw_line.persisted?
        #         Rails.logger.info "Damage waiver order line created [id: %i, amount: %.2f, order: %i, user: %s]" % [dw_line.id, waiver_amount, order.id, @user.email]
        #     else
        #         Rails.logger.error "Damage waiver order line NOT created [amount: %.2f, order: %i, user: %s] %s" % [waiver_amount, order.id, @user.email, dw_line.errors.inspect]
        #         raise OrderLineError, dw_line.errors.inspect
        #     end
        # end
    end

    # Adds product piece locations entries
    # This is how the system keeps track of barcodes. We need to mark each barcode of a
    # product as 'OnOrder' so the ERP knows what to do and it's hidden from the frontend.
    def create_product_piece_locations(order, order_items)
        user = @user.owner.present? ? @user.owner : @user
        order_items_models = Product.where(id: order_items.pluck(:id))

        order_items_models.each do |item|
            item.product_pieces.each do |pp|
                # begin
                    next if pp.void?

                    ppl = ProductPieceLocation.create(
                        product_piece: pp,
                        table_name: 'orders',
                        table_id: order.id,
                        log_type: 'OnOrder',
                        log_status: 'Posted',
                        created_by: user.id,
                        created: Time.zone.now,
                    )
                    binding.pry
                    # ppl[:table_name] = 'orders'
                    
                    ppl.save
                    if ppl.persisted?
                        Rails.logger.info "Product piece location record created: OnOrder [piece id: %i, ppl id: %i, order: %i, user: %s]" % [pp.id, ppl.id, order.id, user.email]
                    else
                        Rails.logger.error "Product piece location record NOT created: OnOrder [piece id: %i, order: %i, user: %s] %s" % [pp.id, order.id, user.email, ppl.errors.inspect]
                        raise ProductPieceError, ppl.errors.inspect
                    end
                # rescue => error
                    # Rails.logger.error "Product piece location record NOT created. Because product pieces not exist.- SQL error (check PPL trigger): [piece id: %i, order: %i, user: %s]" % [pp.id, order.id, @user.email]
                    # raise error
                # end
            end
        end
    end

    # Creates an in-home sales catalog record
    # NOTE: Only applicable to rental orders
    def create_ihs_catalog(order)
        begin
            catalog = IhsCatalog.new(
                order_id:          order.id,
                inhome_flyer:      delivery_data['ihs_flyer'] == '1' ? true : false,
                partner_type:      delivery_data['ihs_partner_type'],
                partner_name:      delivery_data['ihs_partner_name'],
                partner_email:     delivery_data['ihs_partner_email'],
                partner_telephone: delivery_data['ihs_partner_phone'],
            )

            if catalog.save
                Rails.logger.info "IHS catalog created: [order: %i, catalog: %i]" % [ order.id, catalog.id ]
            else
                Rails.logger.debug "IHS catalog NOT created: [order: %i] %s" % [ order.id, catalog.errors.inspect ]
            end
        rescue => error
            Rails.logger.error "IHS catalog NOT created: [order: %i] %s" % [ order.id, error.full_message ]
        end
    end

    # Arrivy task creation (via SAIL)
    # TODO: Add more specific rescues for SAIL exceptions
    def create_arrivy_task(order, intent:, site_id:)
        full_name = delivery_data['shipping_contact_name'].split(' ')
        data = {
            site_id:         site_id,
            order_type:      order.order_type,
            order_id:        order.id,
            delivery_method: delivery_data['shipping_method'],
            site_name:       order.site.name.downcase,
            first_name:      full_name[0],
            last_name:       full_name[1..].join(' '),
            email:           @user.email,
            mobile_number:   billing_data['shipping_contact_phone'],
            company_name:    @user.company_name,
            address1:        shipping_data['shipping_address'],
            address2:        delivery_data['shipping_address2'],
            city:            delivery_data['shipping_city'],
            state:           delivery_data['shipping_state'],
            zipcode:         delivery_data['shipping_zipcode'],
            country:         'USA', # Not currently collecting this
            amount_fields: {
                order_total:    total_by_intent(intent, site_id),
                # NOTE: The order_subtotal in this context is always the subtotal of the rental furniture.
                #       This number is currently used for delivery capacity planning.
                order_subtotal: (order.order_lines.product_lines.map{ |pl| pl.product.rent_per_month }.sum.to_f rescue 0.to_f),
                tax_amount:     tax_by_intent(intent, site_id),
                damage_waiver:  damage_waiver_by_intent(intent, site_id),
            },
	        delivery_date: "%s %s" % [ order.due_date.strftime('%F %T'), Time.zone.now.formatted_offset ],
        }

        if delivery_data['shipping_method'] == 'pickup'
            data[:site_address] = order.site.address.to_hash.slice(:address1, :address2, :city, :state, :zipcode).merge({country: order.site.address.country.name})
        else
            data[:delivery_fields] = {
                dwelling:       delivery_data['delivery_home_type'] || delivery_data['dwelling_other'],
                parking:        delivery_data['delivery_parking'] == 'y' ? '1' : '0',
                levels:         delivery_data['delivery_levels'],
                considerations: delivery_data['delivery_special_considerations'],
                onsite:         1, # Assumed they will be - not collecting this
            }
        end

        begin
            $SAIL.create_arrivy_task(data)
            Rails.logger.info "SAIL/Arrivy call successfuly [order: %i, data: %s]" % [order.id, data.inspect]
        rescue => error
            Rails.logger.error "SAIL/Arrivy call failed [order: %i, data: %s] %s" % [order.id, data.inspect, error.full_message]
            raise SAILError, error.full_message
        end
    end

end

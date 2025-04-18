require 'sdn/cart'
require 'stripe'
class CartController < ApplicationController
    before_action :require_login, :redirect_if_no_cart
    skip_before_action :redirect_if_no_cart, only: [:index, :create]

    # const_def :REQUIRED_SHIPPING_FIELDS, [ 'project_name', 'shipping_method', 'shipping_contact_name', 'shipping_contact_phone',
    #                                        'shipping_address', 'shipping_city', 'shipping_state', 'shipping_zipcode', ]
    # const_def :REQUIRED_DELIVERY_FIELDS, [ 'delivery_date', 'delivery_parking', 'delivery_home_type', 'delivery_levels', ]
    # const_def :REQUIRED_PICKUP_FIELDS,   [ 'pickup_date', 'pickup_time',  ]

    # const_def :REQUIRED_PAYMENT_FIELDS,  [ 'payment_method', ]
    # const_def :REQUIRED_NEW_CARD_FIELDS, [ 'new_card_address1', 'new_card_city', 'new_card_state', 'new_card_zipcode', 'cc_name',
    #                                        'cc_number', 'cc_verification', 'cc_expiration_month', 'cc_expiration_year', ]




    # const_def :REQUIRED_FIELDS_BILL,     [ 'address1', 'city', 'state', 'delivery_phone',
    #                                        'zipcode', 'phone', 'mobile_phone', 'payment_method', ]
    # const_def :REQUIRED_FIELDS_BILL_CC,  [ 'cc_name', 'cc_number', 'cc_verification',
    #                                        'cc_expiration_month', 'cc_expiration_year', ]
    # const_def :REQUIRED_FIELDS_DEL,      [ 'first_name', 'last_name', 'address', 'city', 'state',
    #                                        'zipcode', 'delivery_method', 'delivery_date', ]
    # const_def :REQUIRED_FIELDS_DEL_TYPE, [ 'parking', 'dwelling_type', 'levels', ]
    # const_def :REQUIRED_FIELDS_PU_TYPE,  [ 'pickup_time', ]
    # const_def :VALID_OCCUPATIONS,        [ 'stager', 'builder', 'realtor_broker', 'home_shopper', ]

     # Shipping related constants
        REQUIRED_SHIPPING_FIELDS = [
            'project_name', 'shipping_method', 'shipping_contact_name', 'shipping_contact_phone',
            'shipping_address', 'shipping_city', 'shipping_state', 'shipping_zipcode'
        ].freeze

        # Delivery related constants
        REQUIRED_DELIVERY_FIELDS = [
            'delivery_date', 'delivery_parking', 'delivery_home_type', 'delivery_levels'
        ].freeze

        # Pickup related constants
        REQUIRED_PICKUP_FIELDS = [
            'pickup_date', 'pickup_time'
        ].freeze

        # Payment related constants
        REQUIRED_PAYMENT_FIELDS = [
            'payment_method'
        ].freeze

        # New Card related constants
        REQUIRED_NEW_CARD_FIELDS = [
            'new_card_address1', 'new_card_city', 'new_card_state', 'new_card_zipcode', 'cc_name',
            'cc_number', 'cc_verification', 'cc_expiration_month', 'cc_expiration_year'
        ].freeze

        # Billing related constants
        REQUIRED_FIELDS_BILL = [
            'address1', 'city', 'state', 'delivery_phone',
            'zipcode', 'phone', 'mobile_phone', 'payment_method'
        ].freeze

        # Credit card related billing fields
        REQUIRED_FIELDS_BILL_CC = [
            'cc_name', 'cc_number', 'cc_verification',
            'cc_expiration_month', 'cc_expiration_year'
        ].freeze

        # Delivery related constants
        REQUIRED_FIELDS_DEL = [
            'first_name', 'last_name', 'address', 'city', 'state',
            'zipcode', 'delivery_method', 'delivery_date'
        ].freeze

        # Delivery type-related fields
        REQUIRED_FIELDS_DEL_TYPE = [
            'parking', 'dwelling_type', 'levels'
        ].freeze

        # Pickup type related field
        REQUIRED_FIELDS_PU_TYPE = [
            'pickup_time'
        ].freeze

        # Valid occupations for users
        VALID_OCCUPATIONS = [
            'stager', 'builder', 'realtor_broker', 'home_shopper'
        ].freeze




    # Shows user's cart
    def index
        return render unless @cart
# 
        @items_by_site = @cart.items_by_site
        
        if @cart.items_in_multiple_regions?
            flash.now[:alert] = "We're unable to process orders across multiple regions. Please only add items in Seattle area or Phoenix, but not both."
        end

        checkout_disabled?

        ofs = @cart.items.pluck(:intent).uniq
        @only_for_sale = ofs.size == 1 && ofs.first == 'buy'

        @items_by_site.each_with_index do |site, index|
            if (current_user&.user_group&.group_name == 'Diamond') || 
               (current_user&.site&.site == "RE|Furnish" && current_user&.user_type.capitalize == 'Employee') || 
               (current_user&.site&.site != "RE|Furnish")
                @items_by_site[index][:open_orders] = current_user.orders.open.rentals.for_site(site.id).map do |order|
                    OpenStruct.new( id: order.id, project: order.project_name.presence, address: order.address&.address1 )
                end
            else    
                @items_by_site[index][:open_orders] = current_user.orders.open.rentals.for_site(site.id).select{ |o| !o.frozen? }.map do |order|
                    OpenStruct.new( id: order.id, project: order.project_name.presence, address: order.address&.address1 )
                end
            end    
            
        end

        return render
    end

    # Cart preview used for the dropdown
    def preview
        return render(json: { html: render_to_string(partial: 'layouts/cart_preview', layout: false), qty: @cart.items_sub_total_and_quantity[1] })
    end

    # Add item to user's cart
    # Creates the cart if it doesn't exist
    def create
        @cart = ::Sdn::Cart.new(current_user)
        product = Product.where(id: params[:product_id], active: 'active')&.first

        begin
            @cart.add_item(product, params[:intent],params["room_id"], params[:quantity], params[:remaining_quantity])
            success = true
            # session[:room_product].merge!(params[:product_id] => session[:room_product]["room_id"])
            msg = "\"%s\" added to cart." % [product.name]
            flash.notice = msg unless request.xhr?
        rescue ::Sdn::Cart::CartError => e
            success = false
            msg = e.message
            flash.alert = msg unless request.xhr?
        end

        return render(json: { success: success, message: msg }) if request.xhr?
        return redirect_back(fallback_location: pdp_path(product.id))
    end

    # Remove item from cart
    def destroy
        id = params[:id]
        product = Product.find(id)

        begin
            Cart.destroy_item_from_cart!(@cart, params[:uniq_id], id)
            flash.notice = "\"%s\" removed from cart." % [product.name]
        rescue Exception => e
            flash.alert = e.message
        end

        if URI(request.referrer).path == checkout_process_path
            return redirect_to(cart_path)
        else
            return redirect_back(fallback_location: cart_path)
        end
    end

    def update_items_quantity
        product = Product.find(params[:id])
        pieces_count = product.product_pieces.map{|p| p.id if p.order_line_id == 0 }.compact.count           
        quantity = 0; price_total = 0; price_sub_total = 0;
        c = current_user&.cart if current_user.present?
        cart_items = eval(c.items)
        new_items = []
        product_available_quantity = product.quantity if product.present?
        total_quantity_in_cart = cart_items.select { |item| item[:id] == product&.id }.sum { |item| item[:quantity].to_i }
        if params[:action_type] == 'increase' && total_quantity_in_cart < product.quantity
            if product && pieces_count == params[:quantity].to_i
                render json: { message: "Product can't be added due to low quantity" }
                return
            end       
            cart_items.each do |i|
              quantity += i[:quantity].to_i
              product = Product.find(i[:id])
              if i[:uniq_id] == params[:uid]
                price_sub_total = price_sub_total + ((i[:price].to_f) * (i[:quantity].to_i + 1))
                new_items << {id: i[:id], uniq_id: i[:uniq_id] ,intent:  i[:intent], price: i[:price], quantity: params[:quantity].to_i + 1, room_id: i[:room_id] }
                
                # {"uniq_id" => i["uniq_id"], "id"=> i['id'], "intent"=> i['intent'], "price"=> i['price'], "room_id" => i['room_id'], "quantity" => params[:quantity].to_i + 1}
              else
                price_sub_total = price_sub_total + ((i[:price].to_f) * (i[:quantity].to_i))
                new_items << i                
              end          
            end if cart_items.size > 0 
            price_total = price_sub_total + 200.00
            c.update(items: new_items)
            render json: { cart_items: quantity + 1, new_quantity: params[:quantity].to_i + 1 , sub_total: format('%.2f', price_sub_total) , price_total: format('%.2f', price_total) }
        elsif params[:action_type] == 'decrease'
            if params[:quantity].to_i == 1
                @cart.remove_items(product.id)
                price_sub_total = (params[:total].to_f - product.rent_per_month.to_f) - 200.00
                price_total = price_sub_total + 200.00
                render json: { cart_items: params[:items].to_i - 1, message: "Removed.", sub_total: format('%.2f', price_sub_total) , price_total: format('%.2f', price_total) }
                return
            end
            cart_items.each do |i|              
              if i[:uniq_id] == params[:uid]
                price_sub_total = price_sub_total + ((i[:price].to_f) * (i[:quantity].to_i - 1))
                new_items << {id: i[:id], uniq_id: i[:uniq_id] ,intent:  i[:intent], price: i[:price], quantity: params[:quantity].to_i - 1, room_id: i[:room_id] }
                # {"uniq_id"=> i['uniq_id'], "id"=> i['id'], "intent"=> i['intent'], "price"=> i['price'], "room_id" => i['room_id'], "quantity" => params[:quantity].to_i - 1}
              else
                price_sub_total = price_sub_total + ((i[:price].to_f) * (i[:quantity].to_i))
                new_items << i  
              end          
            end if cart_items.size > 0 
            price_total = price_sub_total + 200.00
            c.update(items: new_items)
            render json: { cart_items: params[:items].to_i - 1, new_quantity: params[:quantity].to_i - 1 , sub_total: format('%.2f', price_sub_total) , price_total: format('%.2f', price_total) }
        else
            render json: { message: "Product can't be added due to low quantity" }    
        end            
    end    

    def update_cart
        c = current_user&.cart if current_user.present?
        new_items = []
        cart_items = eval(c.items)  
        cart_items.each do |i|
          if i[:uniq_id] == params[:product_id].split('select_cart_').last
            new_items << {id: i[:id], uniq_id: i[:uniq_id] ,intent:  i[:intent], price: i[:price], quantity: i[:quantity], room_id: params[:room_id] }
          else
            new_items << i  
          end          
        end if cart_items.size > 0 
        c.update(items: new_items)
    
        # session[:room_product].delete(params[:product_id])
        # session[:room_product].merge!(params[:product_id] => params[:room_id])
        render json: {message: 'ok'}
    end  

    # Removes all items from cart
    def empty
        begin
            cart = Cart.where(user_id: current_user.id)&.first
            cart.update(items: [])
            flash.notice = "Cart emptied."
        rescue  Exception => e
            flash.alert = e.message
        end

        return redirect_to(cart_path)
    end

    # Checkout form to collect billing and shipping info
    def checkout_form
        # binding.pry
        @rush_order = params['rush_order']
        user_must_save_card?
        @user_must_fill_profile = current_user.company_name.blank? || current_user.shipping_address_id.blank?
        @credit_cards = current_user.valid_visible_credit_cards

        # TODO: Add delivery calendar blackout dates
        @scheduling_date_pickup_min = scheduling_date_pickup_min
        @scheduling_date_delivery_min = scheduling_date_delivery_min
        @holidays = BusinessTime::Config.holidays.to_a

        return redirect_to(cart_path) if checkout_disabled?
        return render('checkout_form')
    end

    def checkout_form_handler

        # @rush_order = 
        # @cart.shipping_data['rush_order'] = params['rush_order'].to_i
        
        errors = []
        errors += validate_and_save_company_profile
        errors += validate_credit_card_add_or_not
        errors += validate_and_save_shipping_info unless errors.any?
        # errors += validate_and_save_payment_info unless errors.any?

        if errors.any?
            flash.now[:alert] = errors
            return checkout_form
        end
       
        return redirect_to(checkout_review_path)
    end

    def validate_credit_card_add_or_not
        errors = []
        errors << 'Please add valid credit card.' if current_user.credit_cards.count == 0
        errors.any? ? errors : []
    end    

    def validate_and_save_company_profile
        if params[:company_name].present? || params[:company_address].present?
            current_user.company_name = params[:company_name]
            company_address = Address.new(
                name:       current_user.full_name,
                company:    params[:company_name],
                address1:   params[:company_address1],
                city:       params[:company_city],
                state:      params[:company_state],
                zipcode:    params[:company_zipcode],
                # table_name: 'users',
                # table_id:   current_user.id,
            )
            company_address[:table_name] = 'users'
            company_address[:table_id] = current_user.id
            current_user.shipping_address = company_address
            #  binding.pry    
            if current_user.save
                Rails.logger.info "Company profile saved [user: %s] %s" % [ current_user.email, params.inspect ]
            else
                Rails.logger.debug "Company profile NOT saved [user: %s] %s" % [ current_user.email, current_user.errors.inspect ]
            end
        end

        return [] # Not currently doing any validation on address
    end

    def validate_and_save_shipping_info

        checkout_data = {
            billing: {
                project_name:                 params[:project_name],
                shipping_contact_name:       params[:shipping_contact_name],
                shipping_contact_phone:      params[:shipping_contact_phone],
                new_construction:            params[:new_construction],
                street_number:               params[:street_number],
                route:                       params[:route],
                shipping_address:            params[:shipping_address],
                shipping_city:               params[:shipping_city],
                shipping_state:              params[:shipping_state],
                shipping_zipcode:            params[:shipping_zipcode],
                shipping_method:             params[:shipping_method],
                delivery_home_type:          params[:delivery_home_type],
                delivery_levels:             params[:delivery_levels],
                delivery_special_considerations: params[:delivery_special_considerations],
                rush_order:                  params[:rush_order],
                delivery_date:               params[:delivery_date],
                pickup_date:                 params[:pickup_date],
                pickup_time:                 params[:pickup_time],
                payment_method:              params[:payment_method],
                new_card_address1:           params[:new_card_address1],
                new_card_city:               params[:new_card_city],
                new_card_state:              params[:new_card_state],
                new_card_zipcode:            params[:new_card_zipcode],
                charge_account:              params[:charge_account],
                
                # Optional static or pre-filled fields
                token:                       nil,
                pn_ref:                      current_user&.stripe_customer_id,
                card_type:                   nil,
                last_four:                   nil,
                exp_month:                   nil,
                exp_year:                    nil,
                label:                       nil,
                card_address1:               nil,
                card_city:                   nil,
                card_state:                  nil,
                card_zipcode:                nil,
                card_address_id:             nil
            },

            delivery: {},

            rush_order: params[:rush_order],
            tax_authority: nil,       # Add from context if available
            tax_loc_code: nil,
            tax_rate: "0.0",
            refresh_taxes: false,

            shipping: {
                project_name:                 params[:project_name],
                shipping_contact_name:       params[:shipping_contact_name],
                shipping_contact_phone:      params[:shipping_contact_phone],
                new_construction:            params[:new_construction],
                street_number:               params[:street_number],
                route:                       params[:route],
                shipping_address:            params[:shipping_address],
                shipping_city:               params[:shipping_city],
                shipping_state:              params[:shipping_state],
                shipping_zipcode:            params[:shipping_zipcode],
                shipping_method:             params[:shipping_method],
                delivery_home_type:          params[:delivery_home_type],
                delivery_levels:             params[:delivery_levels],
                delivery_special_considerations: params[:delivery_special_considerations],
                rush_order:                  params[:rush_order],
                delivery_date:               params[:delivery_date],
                pickup_date:                 params[:pickup_date],
                pickup_time:                 params[:pickup_time],
                payment_method:              params[:payment_method],
                new_card_address1:           params[:new_card_address1],
                new_card_city:               params[:new_card_city],
                new_card_state:              params[:new_card_state],
                new_card_zipcode:            params[:new_card_zipcode],
                cc_name:                     params[:cc_name],
                cc_label:                    params[:cc_label],
                charge_account:              params[:charge_account]
            }
        }

        cart = current_user.cart
        cart.checkout = checkout_data
        if cart.save
           return []   
        else
            errors = []
            errors << cart.errors.full_messages 
        end    



        # binding.pry

              
    end

    def validate_and_save_payment_info
        credit_card = params.extract!('cc_label', 'cc_name', 'cc_number', 'cc_verification', 'cc_expiration_month', 'cc_expiration_year')
        errors = []
        method = params['payment_method']
        # TODO: Validate payment fields before filling checkout
        @cart.fill_checkout(params.except(:authenticity_token, :controller, :action, :commit).to_unsafe_hash, 'billing')
        @cart.fill_checkout({cc_save: '1'}, 'billing') if user_must_save_card?
        
        case method
        when 'charge_account'
            
            # @cart.verify_and_load_saved_card(nil)

            account_num = params['charge_account']
            errors << 'Missing required field: Charge Account Number' unless account_num.length > 0
            errors << 'Invalid Charge Account Number.' unless account_num&.to_i > 0 && @cart.verify_charge_account(account_num)
            return errors if errors.any?
        when 'new'
            begin
                # NOTE: Requires billing info correctly saves prior to being called
                @cart.verify_and_tokenize_card(credit_card)
            rescue ::Sdn::Card::MissingDetails => error
                errors << 'Missing credit card details.'
            rescue ::Sdn::Card::InvalidDetails => error
                errors << error.message
            rescue ::Sdn::Card::GatewayError => error
                errors << error.message
            end
            return errors if errors.any?
        else # Saved card number
            begin
                @cart.verify_and_load_saved_card(params['payment_method'])
                # binding.pry
            rescue ::Sdn::Card::DetailsError
                errors << 'Invalid Credit Card selected.'
            end
            return errors if errors.any?
        end

        return []


        # payment_method_id = params[:payment_method_id]

        # if payment_method_id.present?
        #     begin
        #         # Create a customer
        #         customer = Stripe::Customer.create({
        #             email: current_user.email,
        #             name:  "#{current_user.first_name} - #{current_user.last_name}" || current_user.username ,
        #         })

        #         # Attach the payment method to the customer
        #         p = Stripe::PaymentMethod.attach(
        #             payment_method_id,
        #             { customer: customer.id }
        #         )

        #         # Set the default payment method for the customer
        #         customer = Stripe::Customer.update(
        #             customer.id,
        #             invoice_settings: {
        #                 default_payment_method: payment_method_id,
        #             }
        #         )
        #         return [] if customer.present?
        #     rescue Stripe::CardError => e
        #         errors << e.message
        #         return errors if errors.any?
        #     end    
        # else
        #     return []
        # end








    end

    # Review checkout before processing order
    def checkout_review
        # binding.pry
        # ppppppppppp
        return redirect_to(cart_path) if checkout_disabled?
        return render
    end

    # Process and create order
    def checkout_process
        @cart.shipping_data['stripe_id'] = current_user.stripe_customer_id
        # if session["rush_order"] == "No"
        #     @cart.shipping_data['rush_order'] = 0
        # else
        #     @cart.shipping_data['rush_order'] = 1
        # end
        # binding.pry
        @receipt = @cart.process(session[:room_product])

        @payment = @cart.billing_data
        
        if @receipt.orders&.processed.present?
            @receipt.orders&.processed.each do |order|
                due_date = order.due_date.to_date
                customer_id = IntuitAccount.create_quickbooks_customer(current_user) if due_date == Date.today    
                IntuitAccount.create_quickbooks_invoice(order.id, customer_id, false) if order.present? && customer_id.present? && due_date == Date.today    
            end      
        end    
        session[:room_product] = {}
        return redirect_to(project_path(@receipt.orders.processed.first.id)) if @receipt.orders.processed.any?
        return redirect_back(fallback_location: checkout_review_path)
    end
























    # Handle the billing form submission/validation
    # Is this the right way to do this?
    # TODO: Add data format validation (currently only validating required or not)
    def checkout_billing_handler
        # Rip CC from params immediately to avoid any possibility of it living beyond this method call
        credit_card = params.extract!('cc_label', 'cc_name', 'cc_number', 'cc_verification', 'cc_expiration_month', 'cc_expiration_year')
        errors = []
        errors += validate_required_fields(params, REQUIRED_FIELDS_BILL)

        # Save company profile information if applicable



        # Validate payment information
        # TODO: Break this statement on first error in each case (how to do this in ruby?)
        case params['payment_method']
        when 'charge_account'
            account_num = params['charge_account']
            errors << 'Missing required field: Charge Account Number' unless account_num.length > 0
            errors << 'Invalid Charge Account Number.' unless account_num&.to_i > 0 && @cart.verify_charge_account(account_num)
        when 'new'
            begin
                @cart.verify_and_tokenize_card(credit_card)
            rescue ::Sdn::Card::MissingDetails => error
                Rails.logger.debug error.message
                errors << 'Missing credit card details.'
            rescue ::Sdn::Card::InvalidDetails => error
                errors << error.message
            rescue ::Sdn::Card::GatewayError => error
                errors << error.message
            end
        else # Saved card number
            begin
                @cart.verify_and_load_saved_card(params['payment_method'])
            rescue ::Sdn::Card::DetailsError
                errors << 'Invalid Credit Card selected.'
            end
        end

        if errors.any?
            flash.now[:alert] = errors
            return checkout_billing
        else
            @cart.fill_checkout(params.except(:authenticity_token, :controller, :action, :commit).to_unsafe_hash, 'billing')
            @cart.fill_checkout({cc_save: '1'}, 'billing') if user_must_save_card?
            return redirect_to(checkout_review_path)
        end
    end

    def user_must_save_card?
        # binding.pry
        @user_must_save_card = @cart.has_rent_items? && !current_user.has_valid_credit_card?
    end



    # Second checkout step - delivery information form
    def checkout_delivery
        return redirect_to(cart_path) if checkout_disabled?

        @scheduling_date_pickup_min = scheduling_date_pickup_min
        @scheduling_date_delivery_min = scheduling_date_delivery_min
        @renting = @cart.items.pluck(:intent).include?  "rent"
        @buying = @cart.items.pluck(:intent).include?  "buy"
        @holidays = BusinessTime::Config.holidays.to_a

        return render('checkout_delivery')
    end

    # Handle the checkout form submission/validation
    def checkout_delivery_handler
        delivery_method = params[:delivery_method]

        # Populate address with warehouse automatically if sales order and pickup
        if !@cart.items.pluck(:intent).include?("rent") && @cart.items.pluck(:intent).include?("buy") && delivery_method == 'pickup'
            # NOTE: Assumes sales order for one site
            if @cart.items_by_site.first.id == 25
                # PHX Address
                params.merge!({
                                  street_number: '3055',
                                  route:         'E Rose Garden Ln #140',
                                  address:       '3055 E Rose Garden Ln #140',
                                  city:          'Phoenix',
                                  state:         'AZ',
                                  zipcode:       '85050',
                              })
            else
                # SEA Address
                params.merge!({
                                  street_number: '5901',
                                  route:         '23rd Dr West #105',
                                  address:       '5901 23rd Dr West #105',
                                  city:          'Everett',
                                  state:         'WA',
                                  zipcode:       '98203',
                              })
            end
        end

        errors = []
        errors += validate_required_fields(params, REQUIRED_FIELDS_DEL)

        # Validate delivery method
        if delivery_method == 'delivery'
            required_fields = REQUIRED_FIELDS_DEL_TYPE
        else
            required_fields = REQUIRED_FIELDS_PU_TYPE
        end
        errors += validate_required_fields(params, required_fields)

        begin
            scheduling_date = params[:delivery_date].to_date
            if delivery_method == 'delivery' && scheduling_date < scheduling_date_delivery_min
                errors << 'Scheduling date must be at least two business days after today.'
            elsif delivery_method == 'pickup' && scheduling_date < scheduling_date_pickup_min
                errors << 'Scheduling date must be at least one business day after today.'
            end
        rescue => error
            errors << 'Invalid scheduling date requested.'
        end

        # Check if delivery address has changed from what's stored in DB and calc new taxes if so
        # TODO: Move this method to the Cart
        # TODO: Add validation checking for if address is invalid
        old_address = @cart.checkout_data['delivery']&.slice('address', 'city', 'state', 'zipcode')
        new_address = params.slice(:address, :city, :state, :zipcode).to_unsafe_hash
        unless old_address == new_address
            address = {
                line1: params['address'],
                city: params['city'],
                state: params['state'],
                country: params['country'],
                zipcode: params['zipcode'],
            }
            #@cart.calculate_tax(address)
        end

        if errors.any?
            flash.now[:alert] = errors
            return checkout_delivery
        else
            @cart.fill_checkout(params.except(:authenticity_token, :controller, :action, :commit).to_unsafe_hash, 'delivery')
            return redirect_to(checkout_review_path)
        end
    end

    # Updates user profile with billing data if not set
    # Also marks a user record as having completed their signup if anything is saved here.
    def update_user_profile_with_billing_data
        bd = @cart.billing_data
        current_user.first_name = bd['first_name'] unless current_user.first_name.present?
        current_user.last_name = bd['last_name'] unless current_user.last_name.present?
        current_user.company_name = bd['company'] unless current_user.company_name.present?
        current_user.telephone = bd['phone'] unless current_user.telephone.present?
        current_user.mobile = bd['mobile_phone'] unless current_user.mobile.present?
        current_user.default_credit_card = current_user.credit_cards.find_by_token(@receipt.card&.token) unless current_user.default_credit_card.present?

        if current_user.dirty?
            current_user.is_signup_complete = true unless current_user.is_signup_complete
            if current_user.save
                Rails.logger.info "User profile updated from billing info: [user: #{current_user.email}]"
            else
                Rails.logger.error "User profile NOT updated from billing info: [user: #{current_user.email}] #{current_user.errors.inspect}"
            end
        end
    end

    private
        # Redirects user to cart if no cart created
        def redirect_if_no_cart
            unless @cart
                flash.alert = "Cart is empty."
                return redirect_to(cart_path)
            end
        end

        # Determines if checkout can proceed or not
        #   - Disabled if no cart
        #   - Disabled when cart items are across regions
        def checkout_disabled?
            @checkout_disabled = false
            @checkout_disabled = true unless @cart
            @checkout_disabled = @cart.items_in_multiple_regions?

            return @checkout_disabled
        end

        # Scheduling/delivery date minimum
        # TODO: Move this manual hacking of date mins to a config
        def scheduling_date_delivery_min
            2.business_days.after(Date.today)
        end

        def scheduling_date_pickup_min
            1.business_days.after(Date.today)
        end

end

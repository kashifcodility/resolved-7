require 'prawn'
require 'prawn/qrcode'
require 'prawn-rails'
require 'open-uri' # for bg image
require "rubygems" # for color

class InhomeController < ApplicationController

    const_def :MARKUP_PERCENT, 0 # percent expressed as decimal
    const_def :SEA_TAX_RATE, 0.098
    const_def :PHX_TAX_RATE, 0.086
    const_def :CUSTOMER_UID, 7454 # All orders are attributed to this user (inhomesales@sdninc.net)
    const_def :EXCLUDED_CATS, [
                  177, 178, 179, 180, 181, 182, # Mattresses & Box Springs
                  152, 147, # Prop TV's
              ]
    
    before_action {
        @stage_address = order&.address
        @catalog_id = order_id
        @customer = User.get(CUSTOMER_UID)

        @ihs_carts = session[:ihs] || {}        
        @cart = @ihs_carts.fetch(@catalog_id.to_s, { 'cat_id' => @catalog_id, 'products' => [], 'tax_inhome' => 0.0, 'tax_del' => 0.0 })              
    }

    after_action {
        @ihs_carts[@catalog_id.to_s] = @cart
        session[:ihs] = @ihs_carts
    }

    layout "ihs"
    
    def index
        return redirect_to(plp_path, notice: "Catalog ##{order_id} has ended. Please browse our existing available inventory.") unless order

        # TODO: Find sibling orders
        orders = Array(order) #order.sibling_rental_orders(include_source: true)

        @stage_address = order.address
        
        order_product_ids = []
        orders.each do |o|
            order_product_ids += o.order_lines.product_lines.map{ |l| l.product_id }
        end

        @no_filters = true
        @in_home = true
        
        filters = {
            sort:                  params[:sort],
            product_ids:           order_product_ids,
            show_on_frontend_only: false,
            excluded_category_ids: EXCLUDED_CATS,
            hide_private:          false,
        }

        product_ids = Barcode.available_product_ids(filters)
        @product_count = product_ids.size

        # Gets product models and ancillary data/assets
        product_images = Product.get_main_images(product_ids)
        products = Product.all(fields: [ :id, :product, :rent_per_month, :sale_price, :for_sale, :for_rent, :description, :width, :height, :depth ], id: product_ids)

        # Gets sold products
        sold_products = IhsOrder.all(fields: [ :lines ], rental_order_id: @catalog_id)
        sold_pids = sold_products.any? ? sold_products.pluck(:lines).flatten.uniq.pluck('id') : []
        
        @products = products.map do |product|
            OpenStruct.new(
                id:               product.id,
                name:             product.name,
                main_image_url:   product_images.find{ |p| p.product_id == product.id }&.image_url,
                width:            product.width,
                height:           product.height,
                depth:            product.depth,
                description:      product.about,
                sale_price:       calculated_sale_price(product.sale_price),
                for_sale?:        product.for_sale? && !product.id.among?(sold_pids),
                in_cart?:         @cart['products'].find{ |p| p[:id].to_i == product.id }
            )
        end

        # Sort by for sale and then id
        p_availability = @products.partition{ |p| p.for_sale? }
        @products = p_availability[0].sort_by{ |p| p.id }
        @products += p_availability[1].sort_by{ |p| p.id }

        @summary = OpenStruct.new(
            product_count: @cart['products']&.size || 0,
            subtotal:      @cart['products']&.pluck(:p)&.map(&:to_d)&.sum&.to_d || 0,
        )
        
        @show_share = false
        @bc_step = :catalog
        return render
    end

    # TODO: Verify product is available
    def add_to_cart
        return redirect_to(ihs_plp_path(order_id), alert: "Can't checkout with an empty cart.") unless params[:products]
        @cart[:products] = params[:products].to_unsafe_hash.map { |pid, price| { id: pid, p: price } }
        return redirect_to(ihs_checkout_path(order_id))
    end

    def remove_from_cart

    end

    # TODO: Save tax rates and stage delivery to session for processing
    def checkout
        return redirect_to(ihs_plp_path(order_id), alert: "Can't checkout with an empty cart.") unless @cart['products']&.any?

        models = Product.all(id: @cart['products'].pluck(:id))

        @products = @cart['products'].map do |product|
            model = models.find { |p| p.id == product[:id].to_i }
            OpenStruct.new(
                id:    model.id,
                price: product[:p],
                image: model.main_image.url,
                name:  model.name,
            )
        end

        # Calculate tax rate for delivery and save 
        if params[:calculate_tax] == 'true' && params[:delivery_method] == 'delivery'
            addr_type = :delivery
            address = {
                line1:   params[:delivery_address1],
                city:    params[:delivery_city],
                state:   params[:delivery_state],
                country: 'US',
                zipcode:  params[:delivery_zip],
            }
        elsif !session[:ihs_inhome_taxrate]
            addr_type = :inhome
            address = {
                line1:   order.address.address1,
                city:    order.address.city,
                state:   order.address.state,
                country: 'US',
                zipcode: order.address.zipcode,
            }
        end
        
        if address
            avatax_tx = $AVALARA.create_transaction(@products.map{ |p| { id: p.id, price: p.price, product: p.name }}, address)
            ta = $AVALARA.fill_tax_authority_model_with_transaction_response(avatax_tx, TaxAuthority.new)
            if addr_type == :inhome
                @cart['tax_inhome'] = ta.total_rate.to_f
            elsif addr_type == :delivery
                @cart['tax_del'] = ta.total_rate.to_f
            end
        end
                    
        @summary = OpenStruct.new(
            subtotal:               @products.pluck(:price).map(&:to_d).sum,
            delivery:               { inhome: 0, delivery: 169, pickup: 0 },
            will_call_tax_rate:     order.site_id == 25 ? PHX_TAX_RATE : SEA_TAX_RATE,
            stage_address_tax_rate: @cart['tax_inhome'].to_d || 0.00,
            delivery_tax_rate:      @cart['tax_del'].to_d || 0.00,
            order_id:               order_id,
        )
        @summary[:will_call_tax] = (@summary.subtotal * @summary.will_call_tax_rate).round(2)
        @summary[:stage_address_tax] = (@summary.subtotal * @summary.stage_address_tax_rate).round(2)
        @summary[:delivery_address_tax] = (@summary.subtotal * @summary.delivery_tax_rate).round(2)

        @bc_step = :checkout
        return render 'checkout'
    end

    # TODO: This needs some massive cleanup/abstraction
    def transact
        return checkout if params[:calculate_tax] == 'true'
        return redirect_to(ihs_plp_path(order_id), alert: "Can't checkout with an empty cart.") unless @cart['products']&.any?

        models = Product.all(id: @cart['products'].pluck(:id))

        @products = @cart['products'].map do |product|
            model = models.find { |p| p.id == product[:id].to_i }
            OpenStruct.new(
                id:    model.id,
                price: product[:p],
                image: model.main_image.url,
                name:  model.name,
            )
        end

        # Calculate order summary
        @summary = OpenStruct.new(
            subtotal:               @products.pluck(:price).map(&:to_d).sum,
            delivery_method:        params[:delivery_method],
            delivery:               { inhome: 0, delivery: 169, pickup: 0 },
            will_call_tax_rate:     order.site_id == 25 ? PHX_TAX_RATE : SEA_TAX_RATE,
            stage_address_tax_rate: @cart['tax_inhome'].to_d || 0.00,
            delivery_tax_rate:      @cart['tax_del'].to_d || 0.00,
            order_id:               order_id,
        )
        @summary[:will_call_tax] = (@summary.subtotal * @summary.will_call_tax_rate).round(2)
        @summary[:stage_address_tax] = (@summary.subtotal * @summary.stage_address_tax_rate).round(2)
        @summary[:delivery_address_tax] = (@summary.subtotal * @summary.delivery_tax_rate).round(2)
        
        case @summary.delivery_method
        when 'delivery'
            @summary[:tax] = @summary.delivery_address_tax
            @summary[:delivery_total] = @summary.delivery[:delivery]
        when 'pickup'
            @summary[:tax] = @summary.will_call_tax
            @summary[:delivery_total] = @summary.delivery[:pickup]
        else
            @summary[:tax] = @summary.stage_address_tax
            @summary[:delivery_total] = @summary.delivery[:inhome]
        end

        @summary[:total] = @summary.subtotal + @summary.tax + @summary.delivery_total
        
        @billing = OpenStruct.new(
            date:        Time.zone.now.to_date,
            name:        params[:billing_name],
            address:     OpenStruct.new(
                street: params[:billing_address1],
                city:   params[:billing_city],
                state:  params[:billing_state],
                zip:    params[:billing_zip],
            ),
            mobile:      params[:billing_mobile],
            email:       params[:billing_email],
            purchaser:   params[:purchaser],
        )

        @delivery = OpenStruct.new(
            delivery_method: params[:delivery_method],
            name:            params[:delivery_name],
            mobile:          params[:delivery_mobile],
            email:           params[:delivery_email],            
        )
        
        case @delivery.delivery_method
        when 'delivery'
            @delivery[:address] = OpenStruct.new(
                street: params[:delivery_address1],
                city:   params[:delivery_city],
                state:  params[:delivery_state],
                zip:    params[:delivery_zip],
            )
            @delivery[:label] = 'Delivery to your address'
            @delivery[:note] = 'We will contact you to arrange delivery when the stage is complete and your items are available.'
        when 'pickup'
            if order.site_id == 25
                @delivery[:address] = OpenStruct.new(
                    street: '3055 E Rose Garden Ln #140',
                    city:   'Phoenix',
                    state:  'AZ',
                    zip:    '85050',
                )
                @delivery[:label] = 'Pickup at Phoenix warehouse' 
                @delivery[:note] = 'We will contact you to arrange pickup from our Pheonix Warehouse when the stage is complete and your items are available.'               
            else
                @delivery[:address] = OpenStruct.new(
                    street: '5901 23rd Dr West #105',
                    city:   'Everett',
                    state:  'WA',
                    zip:    '98203',
                )
                @delivery[:label] = 'Pickup at Everett warehouse'
                @delivery[:note] = 'We will contact you to arrange pickup from our Everett Warehouse when the stage is complete and your items are available.'                
            end
        else
            @delivery[:address] = OpenStruct.new(
                street: order.address.address1,
                city:   order.address.city,
                state:  order.address.state,
                zip:    order.address.zipcode,
            )
            @delivery[:label] = 'Delivery to staging address'
            @delivery[:note] = 'We will deliver the items to you by leaving them for you when we destage the home.'            
        end

        # Validate credit card
        begin
            cc = ::SDN::Card.new(@customer).from_new_details(
                name:         params[:billing_name],
                number:       params[:cc_number],
                verification: params[:cc_verification],
                exp_month:    params[:cc_expiration_month],
                exp_year:     params[:cc_expiration_year],
                address_1:    params[:billing_address1],
                city:         params[:billing_city],
                state:        params[:billing_state],
                zip:          params[:billing_zip],
            )
        rescue ::SDN::Card::Exceptions::DetailsError => error
            flash.now[:alert] = "Credit card error: #{error.user_message}"
            return checkout
        end
        
        # TODO: Verify all items are transactable

        begin
            ActiveRecord::Base.transaction do
                # Charge card
                @receipt = cc.charge!(@summary.total)

                # Create order/order lines
                ihs_order = IhsOrder.create(
                    rental_order_id:  order_id,
                    lines:            @products.map(&:to_h).to_json,
                    billing_details:  @billing.to_h.to_json,
                    delivery_details: @delivery.to_h.to_json,
                    subtotal:         @summary.subtotal,
                    tax_total:        @summary.tax,
                    delivery_total:   @summary.delivery_total,
                    total:            @summary.total,
                )
                if ihs_order.saved?
                    $LOG.info "IHS order saved: [customer: %s, id: %i]" % [ @billing&.email.to_s, ihs_order.id ]
                    @summary[:ihs_order_id] = ihs_order.id
                else
                    $LOG.debug "IHS order NOT saved: [customer: %s] %s" % [ @billing&.email.to_s, ihs_order.errors.inspect ]
                    raise RuntimeError, "IHS order NOT saved: #{ihs_order.errors.inspect}"
                end
                
                @billing[:transaction] = @receipt.pn_ref
                @billing[:card_last_4] = @receipt.last_four

                # Create payment log
                plog = PaymentLog.new(
                    user_id:         @customer.id,
                    payment_type_id: 11, # ihs_sale
                    cc:              @receipt&.last_four,
                    card_type:       @receipt&.card_type,
                    cc_month:        cc&.exp_month,
                    cc_year:         cc&.exp_year,
                    price:           @receipt&.amount,
                    auth_code:       @receipt&.auth_code,
                    reference:       @receipt&.pn_ref,
                    created_by_id:   13, #admin user
                    stored_card_id:  0,
                )
                if plog.save
                    $LOG.info "Payment log created for IHS sale: [customer: %s, log id: %i]" % [ @billing&.email.to_s, plog.id ]
                    ihs_order.payment_id = plog.id
                    ihs_order.save
                else
                    $LOG.debug "Payment log NOT created for IHS sale: [customer: %s] %s" % [ @billing&.email.to_s, plog.errors.inspect ]
                    raise RuntimeError, "Payment log NOT created for IHS sale: #{plog.errors.inspect}"
                end
                
                # Create transaction
                tx = Transaction.create(
                    response:           'Processed',
                    table_name:         'ihs_orders',
                    table_id:           ihs_order.id,
                    amount:             @receipt.amount.round(2),
                    tax:                @summary.tax.round(2),
                    type:               'Credit Card',
                    cc_last_four:       @receipt.last_four,
                    transaction_number: @receipt.pn_ref,
                    authorization_code: @receipt.auth_code,
                    processed_by:       13,
                    processed_with:     'IHS',
                )

                if tx.saved?
                    $LOG.info "Transaction saved: #{tx.id}"
                    txd = TransactionDetail.create(transaction_id: tx.id, details: @receipt.to_json)
                    if txd.saved?
                        $LOG.info "Transaction details saved: %i [tx: %i]" % [ txd.id, tx.id ]
                        ihs_order.transaction_id = tx.id
                        ihs_order.save

                        # Puts the products on reserve
                        models.each do |p|
                            if p.set_inventory_status!('private', user: @customer)
                                p.reserve_reason = "ihs_cat#%i_trans#%i\n%s" % [ order_id, @billing[:transaction].to_i, p.reserve_reason&.to_s ]
                                if p.save
                                    $LOG.info "Reserve reason set: [product: %i, reason: %s]" % [ p.id, p.reserve_reason ]
                                else
                                    $LOG.debug "Reserve reason NOT set: [product: %i, reason: %s] %s" % [ p.id, p.reserve_reason, p.errors.inspect ]
                                    raise RuntimeError, "Reserve NOT set"
                                end
                            else
                                raise RuntimeError, "Reserve reason not set"
                            end
                        end                        
                    else
                        $LOG.debug "Transaction details NOT saved: [tx: #{tx.id}]"
                        raise RuntimeError, "Transaction details NOT saved: [tx: #{tx.id}]"
                    end
                else
                    $LOG.debug "Transaction NOT saved: [customer: %s] %s" % [ @billing&.email, tx.errors.inspect ]
                    raise RuntimeError,"Transaction NOT saved: [customer: %s] %s" % [ @billing&.email, tx.errors.inspect ]
                end
                
                # Empty cart
                @cart['products'] = []
            end
        rescue ::SDN::Card::Exceptions::Error => error
            $LOG.debug "Credit card charging error: #{error.message}"
            flash.now[:alert] = "Credit card error: #{error.user_message}"
            return checkout
        rescue => error
            $LOG.debug "#{error.full_message}"
            flash.now[:alert] = "Unknown processing error."
            return checkout
        end
        
        IhsMailer.new.send_receipt(@customer, @products, @summary, @receipt, @billing, @delivery).deliver
        
        @bc_step = :confirmation
        return render('confirmation')
    end

    def coversheet
        @font_semibold_path = Rails.root.join('public', 'fonts', 'Montserrat-SemiBold.ttf')
        @font_regular_path = Rails.root.join('public', 'fonts', 'Montserrat-Regular.ttf')   
        @bg_image_path = Rails.root.join('app', 'assets', 'images', 'ihs_coversheet', 'card_mockup.jpg')
        @qrcode_url = ihs_plp_url(order_id) + '?utm_source=InHomeQR&utm_medium=QRCode&utm_campaign=InHomeSales'
        @link_url = ihs_plp_url(order_id) + '?utm_source=InHomeFlyer&utm_medium=Flyer&utm_campaign=InHomeSales'
        qr_url_clean = URI(@qrcode_url).hostname + URI(@qrcode_url).path
        @qrcode_url_display = qr_url_clean.starts_with?('www.') ? qr_url_clean[4..] : qr_url_clean

        # Format phone numbers
        phone = order.user.telephone || order.user.mobile
        clean_phone = phone.delete('^0-9')
        if clean_phone.size == 10
            phone = "(%i) %i-%i" % [ clean_phone[-10..-8].to_i, clean_phone[-7..-5].to_i, clean_phone[-4..].to_i ] rescue phone
        end
        
        @stager = OpenStruct.new(
            first_name: order.user.first_name,
            last_name:  order.user.last_name,
            phone:      phone,
            email:      order.user.email,
        )

        render 'coversheet.pdf'
    end
    
    private

    def order_id
        params[:id].to_i
    end

    def order
        @order ||= Order.first(id: order_id, :status.not => ['Complete', 'Pending', 'Void'], type: 'Rental')
    end

    def calculated_sale_price(base_price)
        (base_price * (1 + MARKUP_PERCENT)).round(2)
    end
    
end

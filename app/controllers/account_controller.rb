require 'sdn/card'
require 'sdn/order'
require 'stripe'
class AccountController < ApplicationController
    before_action :require_login

    def index
        @profile = OpenStruct.new(
            current_user.slice(:first_name, :last_name, :billing_address, :telephone, :email)
            .merge({
            image_url:                current_user.logo_url,
            join_year:                current_user.join_date.year.to_s,
            full_name:                current_user.full_name,
            tax_exempt?:              current_user.tax_exempt?,
            tax_exemption_expires_on: current_user.tax_exemption_expires_on,
            tax_exemption_expired_on: current_user.tax_exemption_expired_on,
            damage_waiver_exempt?:    current_user.damage_waiver_exempt?,
            damage_waiver_expires_on: current_user.damage_waiver_expires_on,
            damage_waiver_expired_on: current_user.damage_waiver_expired_on,
            address:                  OpenStruct.new(current_user.billing_address&.slice(:address1, :address2, :city, :state, :zipcode)),
            credit_cards:             current_user.credit_cards.visible.map { |cc|
                OpenStruct.new(
                   id:          cc.id,
                   type:        cc.card_type.capitalize,
                   last_4:      cc.last_four,
                   month:       cc.month,
                   year:        cc.year, default?: cc.default?,
                   label:       cc.label,
                   order_count: Order.where(credit_card: cc).active.count,
               )},
        }))

        # @locations = Array(Site.all(active: 'Active', :id.not => 23).map { |site| OpenStruct.new(
        #     id:      site.id,
        #     name:    site.name,
        #     address: OpenStruct.new(site.address.to_hash.slice(:address1, :address2, :city, :state, :zipcode)),
        #     default: (current_user.site == site)
        # )})

        render














    end

    # New password form
    def new_password

    end

    # Updates user's password
    def update_password

    end

    # AKA /projects
    def orders       
        # render this from application controller
    end

    def order_invoice
        @order = Order.where(id: params[:ids].to_i)&.first
    end

    def order_invoice_sale
        @order = Order.where(id: params[:ids].to_i)&.first
    end  

    # Shows specific order that user owns
    # AKA projects/:id
    def order_show
    
        order_id = params[:id].to_i

        unless current_user.orders.pluck('id').include?(order_id)
            flash.alert = "Invalid order number."
            return redirect_to(account_path)
        end

        @rooms = Room.active_rooms_ordered_by_position(current_user&.id).map{ |r| OpenStruct.new(id: r.id, name: r.name) }

        # Kind of messy, but merges the manual SQL results with model calls
        # TODO: This needs to be cleaned up... it's a mess.
        order = Order.find(order_id)
        @order_obj = order
        # order_products = Order.rental_order_details(current_user, order_id, status: 'OnOrder')
        @omodel = order   
        @products_form = []
        order_product_lines = lines = order.order_lines.map{|a| a if a.product_id != nil }.compact
        # binding.pry
        @order = OpenStruct.new(
            id:                order.id,
            due_date:          order.due_date,
            email:             order&.user&.email,
            levels:            order.levels,
            company_service:   order.service,
            dwelling:          order.dwelling,
            parking:          order.parking,
            delivery_special_considerations:  order.delivery_special_considerations,
            destage_date:      order.destage_date,
            created_on:        order.ordered_on,
            rental?:           order.rental?,
            completed_on:      order.complete_date,
            completed?:        order.completed?,
            shipped_at:        order.shipped_at,
            shipping_at:       order.shipping_at,
            shipped?:          order.shipped?,
            freezes_at:        order.freezes_at,
            is_frozen?:        order.frozen? || order.shipped?, # NOTE: Can't use OpenStruct#frozen due to reserved keyword
            destaging_at:      order.destaging_at,
            destaged_at:       order.destaged_at,
            rush_order:       order.rush_order,
            destaged?:         order.destaged?,
            rent_starts_on:    order.rent_accrual_starts_on,
            type:              order.order_type,
            shipping_type:     order.service,
            service:           (order.delivery? ? 'Delivery' : 'Will Call'),
            pickup?:           order.pickup?,
            cancelled?:        order.void?,
            destageable?:      order.can_be_destaged?,
            tax_percent:       order&.tax_authority&.total_rate,
            status:            order.status,
            project_walk_through:            order.project_walk_through&.last&.id,
            full_name:         current_user.full_name,
            username:          current_user.username,
            billing_address:   OpenStruct.new(order.billing_address.attributes),
            shipping_address:  OpenStruct.new(order.shipping_address.attributes),
            products: order_product_lines.map{ |ol|
                    ol_model = ol
                    p_model = ol_model&.product
                    @products_form << "#{p_model.id}-#{ol.id}"
                    OpenStruct.new(
                        id:                    p_model.id,
                        rating:                p_model.quality_rating,
                        sku:                   p_model.sku,
                        type:                  ol.line_type,
                        line_id:               ol.id,
                        bin:                   p_model&.bin&.bin, 
                        quantity:              ol.quantity,
                        image_url:             (p_model.main_image.url rescue nil),
                        name:                  p_model.name,
                        total_price_per_month: ol_model.price,
                        base_price_per_month:  p_model.rent_per_month,
                        sale_price:            p_model.sale_price,
                        status:                p_model.status,
                        active?:               p_model.active?,
                        status_updated_date:   Time.now,
                        room:                  ol_model.room.name,
                        voidable?:             (ol_model.voidable? || (session[:god] === true && order.open? && order.rental?) rescue false),
                        added_at:              ol_model.created_at || order.ordered_date,
                        returned_at:           ol_model.returned_at,
                        returned?:             ol_model.returned_at&.present?
                    )
            },
            
            project_name: order.project_name,
            cancellable?: order.cancellable_by_customer? || (session[:god] === true && order.open? && order.rental?),
            credit_card: order.credit_card,
        )

        # Group products by room with unassigned at the top
        @order[:products_by_room] = @order.products.select{ |p| p.room != 'Unassigned' }.group_by{ |p| p.room }
        unassigned_products = @order.products.select{ |p| p.room == 'Unassigned' }
        if unassigned_products.any?
            @order[:products_by_room] = { 'Unassigned' => unassigned_products }.merge(@order[:products_by_room])
        end

        # Group products in each room by currently renting and returned
        @order.products_by_room.each do |room, products|
            renting = products.select{ |p| !p.returned? }.sort!{ |a,b| b.added_at <=> a.added_at }
            returned = products.select{ |p| p.returned? }.sort!{ |a,b| b.added_at <=> a.added_at }
            @order[:products_by_room][room] = renting.concat(returned)
        end

        # NOTE: This line is used when doing async refresh of rooms. See #order_change_product_room
        return @order if request.xhr?

        @soonest_destage_date = Order.soonest_destage_date

        @credit_cards = CreditCard.where(user: current_user).not_expired.visible
        @billing_address = current_user.billing_address || {}

        # Generates future payment info
        @future_payment = order.next_rental_renewal

        if @future_payment
            # Looks for dw and tax excempt members
            @future_7_days = {
                subtotal:  @future_payment.totals[:subtotal],
                tax:  @current_user.tax_exempt? == true ? 0 : ((@future_payment.totals[:subtotal])*(@order.tax_percent || 0)),
                damage_waiver:  @current_user.damage_waiver_exempt? == true ? 0 : @future_payment.totals[:damage_waiver],

            }
            # Gives first 30 day as future payment amount on open or unpaid orders
            @future_30_days = {
                subtotal:  @future_payment.totals[:subtotal]/7*30,
                tax:  @current_user.tax_exempt? == true ? 0 : (((@future_payment.totals[:subtotal])/7*30)*(@order.tax_percent || 0)),
                damage_waiver:  @current_user.damage_waiver_exempt? == true ? 0 : @future_payment.totals[:damage_waiver]/7*30,

            }

            @future_7_total = @future_7_days[:damage_waiver] + @future_7_days[:subtotal] + @future_7_days[:tax]

            @future_30_total = @future_30_days[:damage_waiver] + @future_30_days[:subtotal] + @future_30_days[:tax]
        end

        # Generates past payment info
        payment_history = order.order_fees
        @past_payments = {
            shipping:      payment_history.pluck('shipping').map(&:to_d).sum,
            damage_waiver: payment_history.pluck('waiver').map(&:to_d).sum,
            destage:       payment_history.pluck('destage').map(&:to_d).sum,
            tax:           payment_history.pluck('tax').map(&:to_d).sum,
            other:         payment_history.pluck('charges').map(&:to_d).sum,
            products:      payment_history.pluck('products').map{ |ps| ps.map{ |p| p[1].to_d } }.flatten.sum,
        }
        @past_payments[:total] = payment_history.pluck('amount').map(&:to_d).sum
        @past_payments = OpenStruct.new(@past_payments)

        render
    end

    def ordered_date
        @order = Order.get(params[:id])
        render json: {ordered_date: @order.ordered_date.strftime('%Y-%m-%d')}
    end

    # Handles project edit
    def order_update
        
        order_id = params[:id].to_i

        unless order_id.among?(current_user.orders.pluck('id'))
            flash.alert = "Invalid order number."
            return redirect_to(account_path)
        end

        order = Order.get(order_id)
        
        if params[:stage_info].present?
            order.dwelling = params[:stage_home_type]
            order.levels = params[:stage_levels]
            order.delivery_special_considerations = params[:stage_instructions]
            addr = order.shipping_address
            addr.phone = params[:stage_phone]
            current_user.update(first_name: params[:first_name])
            current_user.update(last_name: params[:last_name])
            addr.address1 = params[:stage_address]
        else
            order.project_name = params[:project_name]
            order.service = params[:shipping_method] == "delivery" ? "Company" : "Self"
            order.dwelling = params[:project_home_type]
            order.levels = params[:project_levels]
            order.due_date = params[:project_delivery_date]
            order.delivery_special_considerations = params[:project_instructions]
            addr = order.shipping_address
            addr.phone = params[:project_phone]
            addr.name = params[:project_contact]
            addr.address1 = params[:project_address]
        end        
        
        

        if addr.save && order.save
            Rails.logger.info "Order updated: [order: %i, user: %s]" % [ order_id, current_user.email ]
            flash.notice = "Successfully updated project."
        else
            Rails.logger.debug "Order NOT updated: [order: %i, user: %s] %s" % [ order_id, current_user.email, order.errors.inspect ]
            flash.error = "Error updating project. Please try again or contact support."
        end

        return redirect_back(fallback_location: project_path(order_id))
    end

    def order_receipt
        @order_ids = params[:ids].split(',').map(&:to_i)

        if current_user.user_type.capitalize == "Employee"
            orders = Order.where(id: @order_ids).not_voided
        else
            orders = Order.where(id: @order_ids, user: current_user).not_voided
        end

        return redirect_to(account_orders_path, alert: 'Invalid order.') if orders.empty?

        @related_orders = orders.first&.sibling_rental_orders(only_currently_renting: false, include_source: true)&.sort if orders.first.address&.present?

        order_fees = OrderFee.where(order_id: @order_ids)
        refund_log = RefundLog.where(line_id: @order_ids)
        order_line = OrderLine.where(order_id: @order_ids)
        extra_fees = ExtraFee.where(order_id: @order_ids)
        transactions = Transaction.where(table_name: 'orders', table_id: @order_ids)

        payments = order_fees.select{ |of| of.amount > 0.02 }.map do |of|
            OpenStruct.new(
                order: of.order_id,
                date: of.updated_at,
                amount: of.amount.to_f,
                auth_id: of.payment_id,
                card_type: of.payment&.card_type || 'Credit Card',
                card_last_4: of.payment&.cc,
                ref: of.payment.pn_ref&.to_s,
            )
        end

        payments += transactions.select{ |tx| tx.response == 'Processed' && tx.amount > 0.02 }.map do |tx|
            OpenStruct.new(
                order: tx.table_id,
                date: tx.transaction_date,
                amount: tx.amount.to_f,
                auth_id: tx.transaction_number,
                card_type: 'Credit Card',
                card_last_4: tx.cc_last_four,
                ref: tx.transaction_number&.to_s,
            )
        end

        payments.sort_by!(&:date)

        payments = payments.uniq { |p| p.ref }
        # De-duplicate based on date/amount/card (some legacy orders have inconsistent refs)
        payments = payments.uniq { |p| [ p.date.strftime('%F'), p.amount.round, p.card_last_4.to_s ] }
        @payment_log = payments

        @order = OpenStruct.new(
            ids:           orders.pluck(:id),
            created_on:    nil, # Order.on_order_date(order.id),
            ended_on:      nil, # order.complete_date,
            product_lines: orders.map{ |o| o.order_lines.product_lines }.flatten.map { |l|
                OpenStruct.new(
                    id:          l.product_id,
                    name:        l.product&.product,
                    type:        l.order.order_type,
                    order:       l.order.id,
                    created_on:  l.created_at&.to_date,
                    shipped_on:  l.shipped_at&.to_date,
                    returned_on: l.returned_at&.to_date,
                    started_on:  ((l.created_at.to_date + 7 < l.shipped_at.to_date ? l.created_at.to_date : l.shipped_at.to_date) rescue l.created_at&.to_date),
                    sales_price: l.order.order_type == 'Sales' ? l.price : 0,
                    base_price:  order_fees.map { |of| of.product_total(l.product_id) }.sum,
                )
            },
            delivery_lines:  order_fees.select { |l| l.shipping > 0 }.map { |l| OpenStruct.new( date: l.updated_at.to_date, amount: l.shipping ) },
            destage_lines:   order_fees.select { |l| l.destage > 0 }.map { |l| OpenStruct.new( date: l.updated_at.to_date, amount: l.destage ) },
            waiver_lines:    order_fees.select { |l| l.waiver > 0 }.map { |l| OpenStruct.new( date: l.updated_at.to_date, amount: l.waiver ) },
            misc_lines:      order_fees.select { |l| l.charges > 0 }.map { |l| OpenStruct.new( date: l.updated_at.to_date, amount: l.charges ) },

            fee_lines:    order_line.select { |l| l.base_price > 0 }.map { |l| OpenStruct.new(
                                            id: l.id,
                                            base_price: l.base_price,
                                            description: l.description,
                                            ) },

            extra_fees:     extra_fees.select { |l| l.charged_id> 0 }.map { |l| OpenStruct.new(
                                                order_line: l.order_line_id,
                                                order_id: l.order_id,
                                                date: l.updated_at.to_date,
                                                type: l.type,
                                                description: l.description,
                                                base_price: l.order_line.base_price,
                                            ) },
            damage_waiver:   order_fees.pluck(:waiver).sum,
            tax_amount:      order_fees.pluck(:tax).sum,
            address:         orders.first&.address,
            billing_address: orders.first.billing_address,
            refunds:         refund_log.map { |rl| OpenStruct.new(
                                                  line_id: rl.line_id,
                                                  status: rl.status,
                                                  amount: rl.amount,
                                                  timestamp: rl.timestamp,
                                                  type: rl.type,
                                                  payment_id: rl.payment_id,
                                                  refund_payment_id: rl.refund_payment_id,
                                                  reason_description: rl.reason_description,
                                              )},

        )

        @order[:subtotal] = @order.product_lines.pluck(:base_price).sum + @order.product_lines.pluck(:sales_price).sum
        @order[:tax_amount] = @order.subtotal * orders.first.tax_authority.total_rate if orders.first.order_type == 'Sales' # Assumes all orders are same tax authority/rate
        @order[:shipping] = @order.delivery_lines.pluck(:amount).sum + @order.destage_lines.pluck(:amount).sum
        @order[:extra_fees_total] = @order.extra_fees.pluck(:base_price).sum - @order.shipping
        @order[:total] = @order.subtotal + @order.tax_amount + @order.delivery_lines.pluck(:amount).sum + @order.destage_lines.pluck(:amount).sum + @order.waiver_lines.pluck(:amount).sum + @order.misc_lines.pluck(:amount).sum
        @order[:total_refund] = @order.refunds.pluck(:amount).sum
        @order[:total_charged] = @payment_log.pluck(:amount).sum
        @order[:total_paid] = @order.total_charged - @order.total_refund

        return render
    end

    def invoice
        # pagination
        page = params[:page]
        if page == 'all'
            @per_page = 42069
            limit = @per_page
            @offset = 0
        else
            @page = page&.to_i || 1
            @per_page = 9
            limit = @per_page
            @offset = @per_page * (@page - 1)
        end
        user_id = current_user.id
        @orders = Order.where(user_id: user_id)
                        .where.not(status: 'void')
                        .limit(@per_page)
                        .offset(@offset)
        @orders_count = @orders.count
        render
    end

    def orders_items_list_receipt
        @order_ids = params[:ids].split(',').map(&:to_i)

        if current_user.type == "Employee"
            orders = Order.all(id: @order_ids).not_voided
        else
            orders = Order.all(id: @order_ids, user: current_user).not_voided
        end

        return redirect_to(account_orders_path, alert: 'Invalid order.') if orders.empty?

        @related_orders = orders.first&.sibling_rental_orders(only_currently_renting: false, include_source: true)&.sort

        @order = OpenStruct.new(
            ids:           orders.pluck(:id),
            created_on:    nil, # Order.on_order_date(order.id),
            ended_on:      nil, # order.complete_date,
            product_lines: orders.map{ |o| o.order_lines.product_lines }.flatten.map { |l|
                OpenStruct.new(
                    id:          l.product_id,
                    name:        l.product.product,
                    type:        l.order.type,
                    order:       l.order.id,
                    active:      l.product.active,
                    created_on:  l.created_at.to_date,
                    shipped_on:  l.shipped_at&.to_date,
                    returned_on: l.returned_at&.to_date,
                    started_on:  ((l.created_at.to_date + 7 < l.shipped_at.to_date ? l.created_at.to_date : l.shipped_at.to_date) rescue l.created_at.to_date),
                    sales_price: l.order.type == 'Sales' ? l.price : 0,
                )
            },
            address:         orders.first&.address,
            billing_address: orders.first.billing_address,
        )

        return render
    end

    def order_receipt_grouped
        return redirect_back(fallback_location: account_orders_path) unless params[:orders]
        return redirect_to(order_receipt_path(params[:orders].join(',')))
    end


    # Voids/removes an order line from order
    def order_void_line
        begin
            ActiveRecord::Base.transaction do  
                order_id = params[:id].to_i
                line_id  = params[:line_id].to_i
                ol = OrderLine.where(id: line_id)&.first
                product_name = ol&.product&.product
                bin_name = params.select { |key, value| key.start_with?('bin_name_') }.values[0]
                bin = Bin.where(site_id: current_user&.site&.id, bin: bin_name)&.first
                bin = Bin.create(site_id: current_user&.site&.id, bin: bin_name, active: 'Active') if bin.blank? && bin_name.present?
                # puts bin.inspect+"BINSSSSSSSSSSSSSSSSSSS"
                product_pieces = ProductPiece.where(order_line_id: line_id)
                # puts product_pieces.inspect+"jjjjjjjjjjjjjjjj"
                # Attributes voiding to impersonator, if applicable
                if session[:god] === true
                    voided_line = OrderLine.get(line_id).void!(voided_by: sdn_impersonator)
                else
                    voided_line = OrderLine.void_line_belonging_to_user(line_id, current_user)
                end
                
                    
                if voided_line

                    invoice_db = Invoice.where(order_id: ol&.order&.id)&.last
                    qbo_invoice_id = invoice_db&.qbo_invoice_id
                    stripe_invoice_id = invoice_db&.stripe_invoice_id
                    # product_pieces.map{ |piece| piece.update(bin_id: bin.id)} if bin.present? && product_pieces.present?
                    IntuitAccount.delete_quickbooks_line_item_from_invoice(product_name, qbo_invoice_id)
                    stripe_service = StripeInvoiceService.new(current_user, ol&.order)
                    stripe_service.delete_invoice_item(product_name, stripe_invoice_id)
                    product_pieces.map{ |piece| piece.update(bin_id: bin.id, status: 'Available')} if bin.present? && product_pieces.present?
                    flash.notice = "Successfully removed \"%s\" from order #%i." % [ voided_line.product, order_id ]
                else
                    flash.alert = "Invalid order line selected."
                end
            end
        rescue Exception => e
            flash.alert = e.message
        end    

        return redirect_back(fallback_location: account_path)
    end

    def order_cancel
        order_id = params[:id].to_i
        order = current_user.orders.first(id: order_id)

        unless order
            flash.alert = "Invalid order."
            return redirect_back(fallback_location: account_path)
        end

        begin
            order = ::Sdn::Order.from_model(order)
            if session[:god] === true
                order.void(voided_by: sdn_impersonator)
            else
                invoice = Invoice.first(order_id: order_id)
                order.cancel
                IntuitAccount.delete_quickbooks_invoice(invoice.qbo_invoice_id) if invoice.present?
            end

            flash.notice = "Successfully cancelled order #{order_id}"
            return redirect_to(account_orders_path)
        rescue ::Sdn::Order::OrderError => error
            flash.alert = "#{error.user_message}"
            return redirect_back(fallback_location: account_path)
        end
    end

    # def order_cancel
    #     order_id = params[:id].to_i
    #     order = current_user.orders.first(id: order_id)

    #     unless order
    #         flash.alert = "Invalid order."
    #         return redirect_back(fallback_location: account_path)
    #     else
    #         order.update(status: "Void")  
    #         flash.notice = "Successfully cancelled order #{order_id}"
    #         return redirect_to(account_orders_path)  
    #     end
    # end

    def order_request_destage
        order_id = params[:id].to_i
        date = params[:destage_date]
        service = params[:destage_service] == 'destage_dropoff' ? 'destage_dropoff' : 'destage'
        expedited = params[:expedited]

        order = current_user.orders.first(id: order_id)

        return redirect_back(fallback_location: account_orders_path, alert: 'Invalid order selected.') unless order

        begin
            ::Sdn::Order.from_model(order).request_destage(date: date, service: service, expedited: expedited, requested_by: current_user)

            return redirect_back(fallback_location: account_orders_path, notice: 'Destage has successfully been requested.')
        rescue ::Sdn::Order::OrderError => error
            return redirect_back(fallback_location: account_orders_path, alert: error.user_message)
        rescue
            return redirect_back(fallback_location: account_orders_path, alert: 'An error has occurred. Please contact us.')
        end
    end

    def accounting_payments
        year = params[:year] || Time.zone.today.year
        month = (1..12).include?(params[:month]&.to_i) ? params[:month] : Time.zone.today.month
        return redirect_to(account_accounting_payments_path + "?year=#{year}&month=#{month}") unless params[:month]
        beginning_of_month = "#{year}-#{month}-01".to_date
        end_of_month = beginning_of_month.end_of_month

        user_commission_percent = (current_user.membership_level&.commission&.base_commission.to_i / 100).to_d

        products = Product.rental_income_for_user(current_user, year:year, month:month)

        @commission_paid = 0
        @current_credit = 0
        @amount_to_pay = 0
        @items_renting = 0
        @products = []

        product_models = Product.where(id: products.pluck('id'))

        products.each do |product|
            model = product_models.find{ |p| p.id == product.id }
            start_rent = product.from_date.to_datetime
            end_rent = product.to_date&.to_datetime || Time.zone.now.to_datetime
            return_date = product.end_date&.to_datetime
            shipped_date = product.start_date&.to_datetime
            earned_commission = product.base_price * user_commission_percent

            item = OpenStruct.new(
                id:             product.id,
                name:           model.name,
                image_url:      model.main_image&.url,
                site_name:      model.site.name,
                days_rented:    (((end_rent - start_rent).to_i.days + 1.day) / 1.day).to_i,
                shipped_date:   shipped_date,
                status:         product.to_date ? 'Returned' : 'Renting',
                return_date:    return_date,
                earned_per_day: earned_commission / 30,
                status_rent:    model.for_rent,
                status_buy:     model.for_sale,
                status_reserve: model.reserved,
            )

            if beginning_of_month <= start_rent # Rented in same month as requested report
                if item.days_rented > 1 || start_rent == end_of_month # Rented on last day of month, skip returned same day (not sure what this really means)
                    item.paid = 0
                    item.pending = 30
                    item.to_pay = earned_commission
                    @amount_to_pay += item.to_pay
                    item.end_rent = product.to_date ? end_of_month : product.to_date
                else
                    item.days_rented = 0
                    item.paid = 0
                    item.pending = 0
                    item.to_pay = 0
                end
            else
                if product.to_date.blank?
                    item.paid = 30
                    item.pending = (Time.zone.now - start_rent).to_i.days - 29.days
                    item.to_pay = 0
                    @commission_paid += item.paid * (earned_commission / 30)
                    @current_credit += item.pending * (earned_commission / 30)
		        elsif product.to_date&.to_datetime <= end_of_month
                    cycle_begin = start_rent + 30.days
                    days_to_pay = (end_rent - cycle_begin).to_i.days + 1.day
                    item.paid = item.days_rented - days_to_pay
                    item.pending = days_to_pay
                    item.to_pay = (earned_commission / 30) - days_to_pay
                    @amount_to_pay += item.to_pay
                    @commission_paid += item.paid * (earned_commission / 30)
                end
            end

            item.earned = item.earned_per_day * item.paid

            @items_renting += 1 unless product.to_date

            @products << item
        end

        # Payments tab data
        @payments = current_user.payments.map{ |payment|
            order = payment.order
            OpenStruct.new(
                reference_number: payment.reference,
                type: humanize_and_capitalize(payment.payment_type.type),
                date: payment.created_at,
                credit_card: payment.cc,
                value: payment.price,
                order: order ? OpenStruct.new( id: order.id, project: order.project_name.presence ) : nil,
            )
        }.sort{ |a,b| b.date <=> a.date }

        render("payments")
    end

    def accounting_income
        year = params[:year] || Time.zone.today.year
        month = (1..12).include?(params[:month]&.to_i) ? params[:month] : Time.zone.today.month
        return redirect_to(account_accounting_income_path + "?year=#{year}&month=#{month}") unless params[:month]
        beginning_of_month = "#{year}-#{month}-01".to_date
        end_of_month = beginning_of_month.end_of_month

        user_commission_percent = (current_user&.membership_level&.commission&.base_commission.to_i / 100).to_d

        products = Product.rental_income_for_user(current_user, year:year, month:month)

        @commission_paid = 0
        @current_credit = 0
        @amount_to_pay = 0
        @items_renting = 0
        @products = []

        product_models = Product.where(id: products.pluck('id'))

        products.each do |product|
            model = product_models.find{ |p| p.id == product.id }
            start_rent = product.from_date.to_datetime
            end_rent = product.to_date&.to_datetime || Time.zone.now.to_datetime
            return_date = product.end_date&.to_datetime
            shipped_date = product.start_date&.to_datetime
            earned_commission = product.base_price * user_commission_percent

            item = OpenStruct.new(
                id:             product.id,
                name:           model.name,
                image_url:      model.main_image&.url,
                site_name:      model.site.name,
                days_rented:    (((end_rent - start_rent).to_i.days + 1.day) / 1.day).to_i,
                shipped_date:   shipped_date,
                status:         product.to_date ? 'Returned' : 'Renting',
                return_date:    return_date,
                earned_per_day: earned_commission / 30,
                status_rent:    model.for_rent,
                status_buy:     model.for_sale,
                status_reserve: model.reserved,
            )

            if beginning_of_month <= start_rent # Rented in same month as requested report
                if item.days_rented > 1 || start_rent == end_of_month # Rented on last day of month, skip returned same day (not sure what this really means)
                    item.paid = 0
                    item.pending = 30
                    item.to_pay = earned_commission
                    @amount_to_pay += item.to_pay
                    item.end_rent = product.to_date ? end_of_month : product.to_date
                else
                    item.days_rented = 0
                    item.paid = 0
                    item.pending = 0
                    item.to_pay = 0
                end
            else
                if product.to_date.blank?
                    item.paid = 30
                    item.pending = (Time.zone.now - start_rent).to_i.days - 29.days
                    item.to_pay = 0
                    @commission_paid += item.paid * (earned_commission / 30)
                    @current_credit += item.pending * (earned_commission / 30)
		        elsif product.to_date&.to_datetime <= end_of_month
                    cycle_begin = start_rent + 30.days
                    days_to_pay = (end_rent - cycle_begin).to_i.days + 1.day
                    item.paid = item.days_rented - days_to_pay
                    item.pending = days_to_pay
                    item.to_pay = (earned_commission / 30) - days_to_pay
                    @amount_to_pay += item.to_pay
                    @commission_paid += item.paid * (earned_commission / 30)
                end
            end

            item.earned = item.earned_per_day * item.paid

            @items_renting += 1 unless product.to_date

            @products << item
        end

        render("income")
    end

    # Commission summaries
    def accounting_rental_income_summary
        year = params[:year].to_i
        return render(json: { success: false, message: 'Invalid year. Please add ?year= to request.' }) unless year.among?((2018..Date.today.year).to_a)

        first_day = Date.new(year, 1, 1)
        last_day = Date.new(year, 12, 31)

        commissions = Commission.all(fields: [ :commission, :cycle, :timestamp ], user: current_user, :cycle.gte => first_day, :cycle.lte => last_day)

        commissions_by_month = commissions.group_by{ |c| c.cycle.month }

        commissions_by_month = (1..12).map do |m|
            date = Date.new(year, m)
            coms = commissions_by_month.find{ |cm,c| cm == m }[1] rescue nil
            total = coms.sum{ |cm| cm.commission }.round(2) if coms
            {
                year:           year,
                month:          m,
                month_name:     date.strftime('%B'),
                average_daily:  coms ? (total / date.end_of_month.day).round(2) : 0,
                average_weekly: coms ? (total / 4).round(2) : 0,
                paid_date:      coms ? coms.last.timestamp.strftime('%D') : 0,
                total:          coms ? total : 0
            }
        end

        populated_months = commissions_by_month.select{|cm| cm[:total] > 0 }
        commissions_ytd = {
            year:            year,
            average_monthly: populated_months.size > 0 ? (populated_months.sum { |c| c[:total] } / populated_months.size).round(2) : 0,
            largest_month:   commissions_by_month.max_by { |c| c[:total] }.slice(:month, :month_name, :total),
            total:           (commissions_by_month.sum   { |c| c[:total] }).round(2),
        }

        data = {
            success: true,
            monthly: commissions_by_month,
            ytd: commissions_ytd,
        }

        render json: data
    end

    # TODO: Abstract these to different methods
    def inventory

        my_inventory_product_ids = current_user.products.pluck('id')
 
        # my_purchased_products = Product.purchased_products_for_user_inventory(current_user.id)
        # my_purchased_product_ids = my_purchased_products.pluck('id')
        # my_purchased_product_models = Product.all(id: my_purchased_product_ids)
 
        my_favorite_product_ids = current_user&.favorites&.compact&.pluck('id') 


       # Fetch the user’s commission percentage (using rescue to handle potential nil values)
        user_commission_percent = ((current_user.membership_level.commission.base_commission / 100).to_d rescue 0)

        # Get the IDs of the user's products
        my_inventory_product_ids = current_user.products.pluck(:id)  # Fetch only IDs to avoid loading unnecessary data

        # Fetch product statuses in one batch (index by product id for faster lookup)
        product_statuses = Product.status_for_user_inventory(my_inventory_product_ids).index_by(&:id)

        # Fetch product images in one batch (index by product id for faster lookup)
        # all_product_images = Product.get_main_images(my_inventory_product_ids).index_by(&:product_id)
        # all_product_images = Product.get_main_images(my_inventory_product_ids + my_purchased_product_ids + my_favorite_product_ids) if my_favorite_product_ids.present?
        
        #    all_product_images = Product.get_main_images(my_inventory_product_ids)
               
        # Pagination settings
        per_page = 10 # Number of products per page
        page = params[:page].to_i > 0 ? params[:page].to_i : 1
        offset = (page - 1) * per_page

        # Paginate the products directly using limit and offset (only fetching necessary products for the current page)
        products = Product.where(id: my_inventory_product_ids)
                            .limit(per_page)
                            .offset(offset)
        @inventory_items = products.map do |product|
            # Get current product status
            current_product_status = product_statuses[product.id]&.status

            # Determine the storage status based on the product's properties
            storage_status = if product.reserved
                                'Private'
                            elsif product.for_rent && product.for_sale
                                'Rent & Sell'
                            elsif product.for_rent
                                'Rent'
                            else
                                nil
                            end

            # Create an OpenStruct for each product with necessary attributes
            OpenStruct.new(
                id: product.id,
                name: product.name,
                image_url: product&.images&.first&.cached_url,
                earned_per_day: product.earned_per_day(user_commission_percent),
                earned_per_month: product.earned_per_month(user_commission_percent),
                price_per_day: product.rent_per_day,
                price_per_month: product.rent_per_month,
                sale_price: product.sale_price,
                last_active_days: product.days_since_last_returned,
                status: current_product_status,
                width: product.width,
                height: product.height,
                depth: product.depth,
                daily_storage_price: ((product.depth * product.width * product.height) / 1728) * 0.03,
                location: product.site&.name,
                storage_status: storage_status
            )
        end

        # Calculate total pages (total items / items per page)
        total_items = Product.where(id: my_inventory_product_ids).size  # Count only the products in the user's inventory
        @total_pages = (total_items / per_page.to_f).ceil if total_items
        @total_pages ||= 1  # Ensure @total_pages has a default value if total_items is nil

        # Set the current page if it's not already set (fallback to page 1)
        @current_page = params[:page].to_i > 0 ? params[:page].to_i : 1

        # Calculate the start and end page for pagination range (max 8-9 links)
        max_pages = 9
        half_range = max_pages / 2
        @start_page = [@current_page - half_range, 1].max
        @end_page = [@current_page + half_range, @total_pages].min

        # Adjust start and end page if we are near the beginning or end of the pages
        if @end_page - @start_page < max_pages - 1
            if @start_page > 1
                @start_page = [@end_page - max_pages + 1, 1].max
            else
                @end_page = [@start_page + max_pages - 1, @total_pages].min
            end
        end

        # "My Purchased" data assembly
        # TODO: This merging of the fucked result set and their models should happen in the model method
       
        # @purchased_products = my_purchased_products.map do |product|
        #     model = my_purchased_product_models.find{ |p| p.id == product.id }
        #     OpenStruct.new(
        #         id: product.id,
        #         name: model.name,
        #         image_url: product&.images&.first&.cached_url, 
        #         # all_product_images&.find{ |pi| pi.product_id == product.id }&.image_url ,
        #         sale_price: model.sale_price,
        #         purchased_date: product.ordered_date&.to_date,
        #     )
        # end
        @purchased_products = []
        # Favorites
        # TODO: Abstract this logic to product model (see products controller also)
        
        favorite_product_ids = Barcode.available_product_ids(**{ favorites_user_id: current_user&.id })
        # product_images = Product.get_main_images(favorite_product_ids)
        flagged_products = Product.get_flags(favorite_product_ids)
        # favorite_products = Product.all(fields: [ :id, :product, :rent_per_month, :sale_price, :for_sale, :for_rent ], id: favorite_product_ids).sort_by!{ |e| favorite_product_ids.index e.id }
        favorite_products = Product
                            .where(id: favorite_product_ids)
                            .select(:id, :product, :rent_per_month, :sale_price, :for_sale, :for_rent)
                            .sort_by { |e| favorite_product_ids.index(e.id) }
        favorite_product_sites = Product.get_sites(favorite_product_ids)
        @favorites = favorite_products.map do |product|
            OpenStruct.new(
                id:               product.id,
                name:             product.name,
                premium?:         flagged_products.find{ |p| p.product_id == product.id }&.premium?,
                closeout?:        flagged_products.find{ |p| p.product_id == product.id }&.closeout?,
                discount_rental?: flagged_products.find{ |p| p.product_id == product.id }&.discount_rental?,
                sales_item?:      flagged_products.find{ |p| p.product_id == product.id }&.sales_item?,
                favorite?:        true,
                main_image_url:   product&.images&.first&.cached_url,  
                # product_images.find{ |p| p.product_id == product.id }&.image_url,
                rent_per_month:   product.rent_per_month,
                sale_price:       product.sale_price,
                for_rent?:        product.for_rent,
                for_sale?:        product.for_sale,
                site:             favorite_product_sites.find{ |p| p.product_id == product.id },
            )
        end
        
        
    end

    # Sets inventory product status
    # NOTE: Product status can be: Private OR (Rent OR (Rent AND Sell))
    # TODO: Move this logic to the model when we implement this functionality in admin.
    def inventory_status_update
        product_edit_log = ProductEditLog.new

        product_id = params[:product_id].to_i
        status = params[:status]

        product = current_user.products.find{ |p| p.id == product_id }
        return json_error('Invalid product.') unless product

        product_edit_log.product_id = product.id
        product_edit_log.action = "storage_status"
        product_edit_log.user_id = current_user.id

        case status
        when 'Private'
            product.reserved = true
            product.for_rent = false
            product.for_sale = false
            product_edit_log.new_value = "private"
        when 'Rent'
            product.reserved = false
            product.for_rent = true
            product.for_sale = false
            product_edit_log.new_value = "rent"
        when 'Rent & Sell'
            product.reserved = false
            product.for_rent = true
            product.for_sale = true
            product_edit_log.new_value = "rent_sell"
        else
            return json_error('Invalid status.');
        end

        # TODO: This is messy and should be in the model
        if product.dirty_attributes.keys.map{ |k| k.name }&.any?{ |k| [:reserved, :for_rent, :for_sale].include?(k) }
            old = product.original_attributes.map { |k,v| [ k.name, v ] }.to_h

            o_reserved = old.fetch(:reserved, product.reserved)
            o_for_rent = old.fetch(:for_rent, product.for_rent)
            o_for_sale = old.fetch(:for_sale, product.for_sale)

            product_edit_log.old_value = 'private'   if o_reserved and !o_for_rent and !o_for_sale
            product_edit_log.old_value = 'rent'      if !o_reserved and o_for_rent and !o_for_sale
            product_edit_log.old_value = 'rent_sell' if !o_reserved and o_for_rent and o_for_sale
        end

        if product.save
            Rails.logger.info "Product status changed: [product: %i, private: %s, rent: %s, sale: %s, user: %s]" % [ product.id, product.reserved.to_s, product.for_rent.to_s, product.for_sale.to_s, current_user.email ]

                if product_edit_log.save
                    Rails.logger.info "Product Edited: [product: %i, private: %s, rent: %s, sale: %s, user: %s]" % [ product.id, product.reserved.to_s, product.for_rent.to_s, product.for_sale.to_s, current_user.email ]
                else
                    Rails.logger.error "Product Not Edited: [product: %i, private: %s, rent: %s, sale: %s, user: %s] %s" % [ product.id, product.reserved.to_s, product.for_rent.to_s, product.for_sale.to_s, current_user.email, product_edit_log.errors.inspect ]
                end

            return json_success('Status updated.')
        else
            Rails.logger.error "Product status NOT changed: [product: %i, private: %s, rent: %s, sale: %s, user: %s] %s" % [ product.id, product.reserved.to_s, product.for_rent.to_s, product.for_sale.to_s, current_user.email, product.errors.inspect ]
            return json_error('Error updating status.');
        end
    end

    def create_inventory_favorite
        product_id = params[:product_id].to_i
        product = Product.get(product_id)
        log_params = [ current_user&.email, product_id ]

        unless product
            Rails.logger.debug "Favorite NOT created for user - invalid product: %s [product: %i]" % log_params
            return render(json: { success: false, message: "Invalid product." })
        end

        begin
            favorite = UserWishlist.create(user_id: current_user.id, product_id: product.id)

            if favorite.saved?
                Rails.logger.info "Favorite created for user: %s [product: %i, wishlist: %i]" % (log_params << favorite.id)
                return render(json: { success: true, message: "Favorite created." })
            else
                Rails.logger.error "Favorite NOT created for user: %s [product: %i] %s" % (log_params << favorite.errors.inspect)
                return render(json: { success: false, message: "Error creating favorite." })
            end
        rescue => error
            Rails.logger.error "Favorite NOT removed for user: %s [product: %i] %s" % (log_params << error.full_message)
            return render(json: { success: false, message: "Error creating favorite." })
        end

        return render(json: { success: true })
    end

    def remove_inventory_favorite
        product_id = params[:product_id].to_i
        favorite = current_user.wishlist.first(product_id: product_id)
        log_params = [ current_user&.email, favorite&.id.to_i, product_id ]

        unless favorite
            Rails.logger.debug "Favorite NOT removed for user - invalid product: %s [wishlist: %i, product: %i]" % log_params
            return render(json: { success: false, message: "Invalid favorite." })
        end

        begin
            if favorite.destroy
                Rails.logger.info "Favorite removed for user: %s [wishlist: %i, product: %i]" % log_params
                return render(json: { success: true, message: "Favorite removed." })
            else
                Rails.logger.error "Favorite NOT removed for user: %s [wishlist: %i, product: %i] %s" % (log_params << favorite.errors.inspect)
                return render(json: { success: false, message: "Error removing favorite." })
            end
        rescue => error
            Rails.logger.error "Favorite NOT removed for user: %s [wishlist: %i, product: %i] %s" % (log_params << error.full_message)
            return render(json: { success: false, message: "Error removing favorite." })
        end
    end

    # Updates user profile
    # TODO: Add validation
    def edit_profile_handler
        errors = []

        if params[:photo]
            errors << 'Photo too large. Max size is 1 MB.' unless params[:photo].size <= 1000000
            errors << 'Invalid file. Allowed: JPG, PNG, GIF' unless params[:photo].content_type.among?("image/jpeg", "image/pjpeg", "image/png", "image/x-png", "image/gif")

            unless errors.any?
                new_filename = "#{current_user.full_name}_#{Time.zone.now.to_i}_#{params[:photo].original_filename}".parameterize.underscore

                unless $AWS.s3.upload(
                        params[:photo].tempfile,
                        bucket: $AWS.s3.bucket(User::S3_BUCKET_LOGOS).name,
                        as: new_filename,
                    )

                    errors << 'Error uploading photo.'
                else
                    current_user.logo_path = new_filename
                    errors << 'Error saving photo.' unless current_user.save
                end
            end
        end

        current_user.attributes = {
            first_name:   params[:first_name],
            last_name:    params[:last_name],
            telephone:    params[:telephone],
            company_name: params[:company_name],
        }
        if current_user.save
            Rails.logger.info "Updated profile for %s." % [ current_user.email, current_user.inspect ]
        else
            errors << 'Error updating profile.'
            Rails.logger.error "Error updating profile for %s. | %s" % [ current_user.email, current_user.errors.inspect ]
        end

        billing_address = Address.first_or_new(
            id:         current_user&.billing_address_id,
            active:     'Active',
            table_name: 'users',
            table_id:   current_user.id,
        )
        billing_address.attributes = {
            address1:   params[:address_1],
            address2:   params[:address_2],
            city:       params[:city],
            state:      params[:state],
            zipcode:    params[:zipcode],
        }
        new_address = billing_address.new?

        if billing_address.save
            if new_address
                current_user.billing_address_id = billing_address.id
                if current_user.save
                    Rails.logger.info "New billing address saved to user. [user: %s, address: %i]" % [ current_user.email, billing_address.id ]
                else
                    Rails.logger.debug "New billing address NOT saved to user. [user: %s, address: %i] %s" % [ current_user.email, billing_address.id, current_user.errors.inspect ]
                end
            end
            Rails.logger.info "Updated billing address for %s." % [ current_user.email ]
        else
            errors << 'Error updating profile.'
            Rails.logger.error "Error updating billing address for %s. | %s" % [ current_user.email, current_user.billing_address.errors.inspect ]
        end

        if errors.any?
            flash.alert = errors
            return redirect_to(account_path)
        else
            flash.notice = "Succesfully updated profile."
            return redirect_to(account_path)
        end
    end

    # Removes payment method (credit card)
    # TODO: Add validation
    def remove_payment_method_handler
        cc_id = params[:id].to_i
        card = CreditCard.find(cc_id)
        last4 = card&.last_four
        if last4.present?
            begin
                payment_methods = Stripe::PaymentMethod.list({
                    customer: current_user.stripe_customer_id,
                    type: 'card',
                })
                
                card_id =  payment_methods.data.map{|d| d.id if d.card.last4 == last4 }.compact&.last
                
                f = Stripe::PaymentMethod.detach(card_id) if card_id.present?
                
                card.destroy 
                flash.notice = "Credit card successfully removed."
                return redirect_to(account_path)
            rescue Stripe::InvalidRequestError => e
                flash.notice = e
                return redirect_to(account_path)
            end    
        else
            flash.notice = "Credit card can't removed."
            return redirect_to(account_path)
        end        
        # credit_card = current_user.credit_cards.find { |cc| cc.id == cc_id }

        # return redirect_to(account_path, alert: "You must have one active default card.") unless CreditCard.all(user: current_user).not_expired.visible.count > 1
        # return redirect_to(account_path, alert: "Can't remove default card. Please select a new default card first.") if credit_card == current_user.default_credit_card
        # return redirect_to(account_path, alert: "Can't remove credit card until all associated orders have been updated with new payment details.") if Order.all(status: ['Open', 'Renting', 'Pulled', 'Pending', 'InTransit'], credit_card: credit_card).count > 0

        # unless credit_card
        #     Rails.logger.debug "User %s tried deleting a credit card (ID %i) they don't own." % [ current_user.email, cc_id ]
        #     flash.alert = "Error removing the credit card."
        #     return redirect_to(account_path)
        # end

        # last_4 = credit_card.last_four
        # if credit_card.disable!
        #     Rails.logger.info "User %s disabled card (ID %i) ending with %s." % [ current_user.email, cc_id, last_4 ]
        #     flash.notice = "Credit card successfully removed."
        #     return redirect_to(account_path)
        # else
        #     Rails.logger.error "Failed disabling card (ID %i) ending with %i, for user %s. | %s" % [ cc_id, last_4, current_user.email, credit_card.errors.inspect ]
        #     flash.alert = "Error removing credit card."
        #     return redirect_to(account_path)
        # end
    end

    # Form for creating new credit card
    def new_credit_card
        @billing_address = current_user.billing_address || {}
        render "new_credit_card"
    end

    # Creates the credit card
    def create_credit_card
        # begin  this code is using payleap that's why comment out. now using stripe.
        #     card = ::Sdn::Card.new(current_user).from_new_details(params.to_unsafe_hash.symbolize_keys)
        #     card_model = card.to_model
        #     card_model.label = params[:label]
        #     unless card_model.save
        #         Rails.logger.error "User credit card model NOT saved: [user: %s] %s" % [ current_user.email, card_model.errors.inspect ]
        #         msg = "Error saving credit card. Please try again."

        #         if request.xhr?
        #             return render(json: { success: false, message: msg })
        #         else
        #             flash.now[:alert] = msg
        #             return new_credit_card
        #         end
        #     end
        # rescue ::Sdn::Card::Exceptions::Error => error
        #     Rails.logger.error "User credit card NOT created: [user: %s] %s" % [ current_user.email, error.message ]
        #     if request.xhr?
        #         return json_error(error.user_message)
        #     else
        #         flash.now[:alert] = error.user_message
        #         return new_credit_card
        #     end
        # end

        # Rails.logger.info "User credit card created: %i [user: %s, type: %s, last 4: %s]" % [ card_model.id, current_user.email, card_model.type, card_model.last_four ]

        # msg = "Successfully added new #{card.card_type} card."
        # if request.xhr?
        #     # TODO: Update this to use the json_success helper (data attributes need to be remapped on FE)
        #     return render(json: { success: true, message: msg, id: card_model.id, display: card_model.display })
        # else
        #     return redirect_to(account_path, notice: msg)
        # end

        payment_method_id = params[:payment_method_id]

        if payment_method_id.present?
            begin
                customer_id = current_user.stripe_customer_id
 
                if customer_id.present?
                  customer = Stripe::Customer.retrieve(customer_id) 
                else  

                # Create a customer
                    customer = Stripe::Customer.create({
                        email: current_user.email,
                        name:  "#{current_user.first_name} - #{current_user.last_name}" || current_user.username ,
                        address: {
                        line1: params[:line1],
                        line2: params[:line2],
                        city: params[:city],
                        state: params[:state],
                        postal_code: params[:postal_code]
                        }
                    })
                end

                current_user.update(stripe_customer_id: customer.id) if customer.present?
                # Attach the payment method to the customer
                p = Stripe::PaymentMethod.attach(
                    payment_method_id,
                    { customer: customer.id }
                )

                # Set the default payment method for the customer
                customer = Stripe::Customer.update(
                    customer.id,
                    invoice_settings: {
                        default_payment_method: payment_method_id,
                    }
                )
            
            rescue Stripe::CardError => e
                deleted_customer = Stripe::Customer.delete(customer.id)
                current_user.update(stripe_customer_id: nil)
                flash[:notice] =  e.message
                render :new_credit_card                
                return 
            end

            CreditCard.create(user_id: current_user.id, customer_key: customer.id,
                              type: p['card']['brand'], last_four: p['card']['last4'], month: p['card']['exp_month'],
                              year: p['card']['exp_year'],created_with: 'StoreCard',visible: 1, updated_with: 'StoreCard',
                              updated_by: current_user.id, info_key: customer.created,created_by: current_user.id, label: params[:label]) if customer.present? && p.present?
            
            if current_user.cart&.items&.present?
              redirect_to '/checkout'
            else
              redirect_to '/account'
            end      
            flash[:notice] =  'Card added.'
        end


    end

    # def create_bin
    #   bin = Bin.new(site_id: current_user&.site&.id, bin: params[:name], active: 'Active')     
    #   if bin.save
    #     product_pieces = ProductPiece.all(order_line_id: params[:line])
    #     product_pieces.each do |product_piece| 
    #         product_piece.bin_id = bin.id
    #         product_piece.save
    #     end
    #     product_pieces&.first&.product&.update(bin_id: bin.id)     
    #     redirect_to account_order_path(params[:order_id]) || root_path, notice: 'Bin created successfully.'
    #   else
    #     redirect_to account_order_path(params[:order_id]) || root_path, alert: 'Error creating bin.'  
    #   end    
    # end   

    def set_default_credit_card
        card_id = params[:card_id].to_i
        return render(json: { success: false }) unless card_id.among?(current_user.credit_cards.not_expired.pluck(:id))
        return render(json: { success: true }) if CreditCard.get(card_id).default!
        return render(json: { success: false })
    end

    # Sets user's default location
    def set_default_location_handler
        new_site_id = params[:id].to_i
        site = Site.first(id: new_site_id, active: 'Active')

        unless site
            Rails.logger.debug "User %s changing default site to non-existent site (ID %i)." % [ current_user.email, new_site_id ]
            flash.alert = "Error changing default location."
            return redirect_to(account_path)
        end

        current_user.site_id = new_site_id

        if current_user.save
            Rails.logger.info "User %s updated their default location to %s (%i)." % [ current_user.email, site.name, new_site_id ]
            flash.notice = "Default location successfully updated."
            return redirect_to(account_path)
        else
            Rails.logger.error "Failed updating default location to %s (%i) for user %s. | %s" % [ site.name, new_site_id, current_user.email, current_user.errors.inspect ]
            flash.alert = "Error changing default location."
            return redirect_to(account_path)
        end

    end

    # Changes room of product/order line
    def order_change_product_room
        order_id = params[:id].to_i
        order_line_id = params[:line_id].to_i
        room_id = params[:room_id].to_i

        unless order_id.among?(current_user.orders.pluck('id'))
            flash.alert = "Invalid order number."
            return redirect_back(fallback_location: account_path)
        end

        order = Order.get(order_id)

        unless order_line_id.among?(order.order_lines.pluck('id'))
            flash.alert = "Invalid order line."
            return redirect_back(fallback_location: account_path)
        end

        order_line = order.order_lines.find{ |ol| ol.id == order_line_id }
        room = Room.get(room_id)

        unless room
            flash.alert = "Invalid room selected."
            return redirect_back(fallback_location: account_path)
        end

        order_line.room_id = room_id

        if order_line.save
            Rails.logger.info "Order line %i (Order %i) room updated to %s (%i)." % [order_line_id, order_id, room.name, room_id]
            if request.xhr?
                order_show
                return render(json: { success: true, html: render_to_string(partial: 'rooms', locals: { order: order_show }, layout: false), })
            else
                flash.notice = "Successfully changed the room to #{room.name} for #{order_line.product.name}."
                return redirect_back(fallback_location: account_path)
            end
        else
            Rails.logger.error "Error updating order line %i (Order %i) room to %s (%i). | %s" % [order_line_id, order_id, room.name, room_id, order_line.errors.inspect]
            message = "Error updating the room for #{order_line.product.name}."
            if request.xhr?
                return render(json: { success: false, message: message })
            else
                flash.alert = message
                return redirect_back(fallback_location: account_path)
            end
        end
    end

    # TODO: Add mechanism to create a new card
    def order_update_credit_card
        order_id = params[:id].to_i
        card_id = params[:card_id].to_i

        begin
            $DB.transaction do

                order = ::Sdn::Order.from_model(Order.get(order_id))
                cc = CreditCard.get(card_id)
                order.update_credit_card(cc)

                msg = "#{cc.display} was successfully assigned to this order for future billing."
                if request.xhr?
                    return json_success(msg)
                else
                    return redirect_back(fallback_location: account_order_path(order_id), notice: msg)
                end

            end
        rescue ::Sdn::Order::Exceptions::UpdateCreditCardError => error
            if request.xhr?
                return json_error(error.user_message)
            else
                return redirect_back(fallback_location: account_order_path(order_id), alert: error.user_message)
            end
        end
    end

    # Adds product(s) to an existing order
    def order_add_products

        begin
            intent     = 'rent'
            order_id   = params[:order_id].to_i
            site_id    = params[:site_id].to_i
            product_id = params[:product_id]&.to_i

            cart = ::Sdn::Cart.new(current_user)
            order_model = Order.find(order_id)
            order = ::Sdn::Order.from_model(order_model)

            if current_user&.user_group&.group_name != 'Diamond' &&
               current_user&.user_type.capitalize != 'Employee' && 
               current_user&.site&.site == "RE|Furnish" &&
               !current_user&.roles&.include?(Role.find_by(role: "Site Manager"))
                redirect_to cart_path, alert: "Order locked. items can't be added."
                return
            elsif cart.items.map{|i| i[:site_id]}.size > 1  
                redirect_to cart_path, alert: "Order items can't be added from more than one site. You can create a new order with items from multiple sites."
                return  
            end

            if product_id
                products = [{ product: Product.find(product_id) }]
            else
                products = cart.items.select{ |e| e[:site_id] == site_id  }.map { |p| { product: Product.find(p[:id]), price: p[:price], intent: p[:intent], room: p[:room_id], quantity: p[:quantity] } }
            end

            product_ids = products.map{ |p| p[:product].id }

            unless order_model.user == current_user
                Rails.logger.debug "Product NOT added to order - invalid order: [products: %i, order: %i, user: %i]" % [ product_ids.join('/'), order_id, current_user&.email ]
                
            end


            invoice_id = order_model&.invoices&.last&.qbo_invoice_id

            if invoice_id.blank?
                # create invoice here for blank orders created by admin.               
                ActiveRecord::Base.transaction do  
                    order.add_products(products, email_receipt: true, user_override: current_user)
                    # new_lines = order_model.order_lines
                    # filtered_order_lines = new_lines.select{ |line| product_ids.include?(line.product_id) }
                    # # invoice_id = order_model&.invoices&.last&.qbo_invoice_id                    
                    # IntuitAccount.update_quickbooks_invoice(invoice_id, filtered_order_lines) if invoice_id.present?
                    customer_id = IntuitAccount.create_quickbooks_customer(current_user)
                    IntuitAccount.create_quickbooks_invoice(order_model.id, customer_id, false) if customer_id.present?
                    service = StripeInvoiceService.new(current_user, order_model) 
                    invoice = service.create_invoice(false)  if order_model.present?
                    current_user.cart.update(items: {}) unless product_id
                end
            else
                # create invoice here for already existing orders with order lines.
                ActiveRecord::Base.transaction do  
                    order.add_products(products, email_receipt: true, user_override: current_user)
                    new_lines = order_model.order_lines
                    filtered_order_lines = new_lines.select{ |line| product_ids.include?(line.product_id) }
                    added_lines = filtered_order_lines.group_by { |order_line| order_line.product_id }.values.map(&:last)
                    # invoice_id = order_model&.invoices&.last&.qbo_invoice_id
                    service = StripeInvoiceService.new(current_user, order_model)
                    invoice_id_stripe = order_model&.invoices&.last&.stripe_invoice_id
                    service.update_invoice(added_lines, invoice_id_stripe)
                    IntuitAccount.update_quickbooks_invoice(invoice_id, added_lines) if invoice_id.present?
                    current_user.cart.update(items: {}) unless product_id
                end
            end

            msg = "Successfully added #{product_ids.size} products to order #{order_id}."
            return json_success(msg) if request.xhr?
            path = cart.items.size > 0 ? cart_path : account_order_path(order_id)
            return redirect_to(path, notice: msg)

        rescue => error
              flash.alert = error.message
        end

        return json_error(msg) if request.xhr?
        return redirect_to(cart_path, alert: msg)
    end

    def add_query
        @order = Order.find(params[:id])
        order_query = OrderQuery.new(message: params[:query], is_customer: true, user_id: current_user.id, order_id: @order.id)
        errors = []

        if params[:file]
            errors << 'Photo too large. Max size is 1 MB.' unless params[:file].size <= 1.megabyte

            unless errors.any?
                new_filename = "#{current_user.username}_#{Time.zone.now.to_i}_#{params[:file].original_filename}"
                s3_bucket = 'sdn-content'

                # Perform the upload
                # upload_success = $AWS.s3.upload(
                #     params[:file].tempfile,
                #     bucket: s3_bucket,
                #     as: new_filename,
                # )

                file_url = Order.upload_to_s3(file: params[:file].tempfile, bucket: s3_bucket, filename: new_filename)


                if file_url
                    # Generate the file URL
                    # file_url = $AWS.s3.public_url_for(new_filename, bucket: s3_bucket)
                    order_query.image_url = file_url
                else
                    errors << 'Error uploading photo.'
                end

                puts 'received your file. now move to the next step'
            end
        end

        if order_query.save
            redirect_to project_path(@order.id)
        else
            # Handle the case where the query could not be saved
            flash[:error] = "Error saving order query: #{errors.join(', ')}"
            redirect_back(fallback_location: root_path)
        end
    end

end

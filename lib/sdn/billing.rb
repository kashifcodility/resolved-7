# Handles routine billing operations
# 
# Author: Jimmy Gleason <jimmy@sdninc.co>
#
#

require 'sdn/db'
require 'sdn/card'

class SDN::Billing


    # Processes charging rent on open rental orders
    #
    # Overview:
    #
    # The method for billing is to treat each order's lines (synonymous with a product) as individually
    # calculated entities within the order versus the order as a whole. This granularily allows for
    # cases where products can be added/removed/delivered/returned from an order at different times.
    # From a business perspective, an order should be synonymous with a staging project/address and in
    # this billing context an order represents the sum of applicable lines' charges.
    #
    # Docs:
    #
    # TODO:
    # - Run billing off last successful billing date, not a fixed past BILLING_INTERVAL_DAYS. This will
    #   help reduce manual efforts to collect older debts.
    # - (partially implemented) Add charging for voided lines that existed on the order beyond the grace period.
    #   There needs to be a discussion around business rules on how this is billed since the renewal date is based
    #   on the line's delivery date, and a voided line isn't delivered.
    # - Verify/finish test coverage.
    # - Cleanup console/debug output.
    #
    class Rent
        attr_accessor :today, :dry_run, :order_actions


        const_def :EXCLUDED_USER_IDS,           [ 2531, 2682, 1709 ] # Skip orders belonging to these user ID's
        const_def :GRACE_PERIOD_DAYS,           7  # Number of days between order initial creation and shipment date
        const_def :INITIAL_DAYS_CHARGED,        30 # Number of days charged upon delivery
        const_def :BILLING_INTERVAL_DAYS,       7  # Billing cycle is every 7 days
        const_def :SKIP_IF_CHARGED_WITHIN_DAYS, 2  # Skip charging an order if a charge has happened within past days
        const_def :BLACKOUT_DATES,              [ { start: '2020-03-27', end: '2020-04-06' } ] # TODO: Move these to the DB
        const_def :ADMIN_USER_ID,               13 # orders@sdninc.net - Used for attributing DB actions to admin


        def initialize(today: nil, dry_run: true, skip_on_hold: true)
            @today = today || Time.zone.today
            @dry_run = dry_run
            @skip_on_hold = skip_on_hold
            @order_actions = []

            $LOG.debug "DRY RUN ACTIVE - NO DB CREATES/UPDATES, EMAILS AND CHARGES WILL BE MADE - MAKE SURE THEIR CONFIGS ARE CORRECT" if dry_run            
        end

        # TODO: Clean this up and abstract it
        def process
            order_count = open_rental_orders.size
            $LOG.info "Starting rent billing of #{order_count} open rental orders..."          
            total_charged = 0.to_d
            orders_charged = []
            orders_not_charged = []

            open_rental_orders.each do |order|
                order_id = order.id
                order_created_on = order.ordered_on.to_date

                o = Rent::Order.new(order, today: today, dry_run: dry_run)

                if o.already_charged?
                    @order_actions << { id: order_id, action: :skipped, note: "Charged within past #{SKIP_IF_CHARGED_WITHIN_DAYS} days" }
                    $LOG.info "Order already charged (check order_fees): #{order_id}"
                    next
                end

                if o.compile && o.skipped_because.blank?
                    if o.subtotal > 0
                        receipt = o.charge!
                        if receipt
                            o.send_receipt_email!
                            total_charged += receipt.total
                            orders_charged << o
                            @order_actions << { id: order_id, action: :charged }
                        else
                            orders_not_charged << o
                            @order_actions << { id: order_id, action: :failed_charge }
                            o.create_failed_billing_record
                            o.send_receipt_email!
                        end
                    else
                        @order_actions << { id: order_id, action: :skipped, note: 'Order subtotal is zero' }
                    end
                else
                    @order_actions << { id: order_id, action: :skipped, note: o.skipped_because || 'Unknown' }
                end
            end

            send_report_email!(total_charged, orders_charged, orders_not_charged) if orders_charged.any? or orders_not_charged.any?

            $LOG.info "Finished. [total orders: %i, charged: %i, not charged: %i, total amount: %.2f]" % [ order_count, orders_charged.count, orders_not_charged.count, total_charged ]
        end

        # TODO: Update tests
        def open_rental_orders
            ::Order.all(:id.not => orders_to_skip).renting_rentals
        end

        # TODO: Add tests
        def orders_to_skip
            ids = []
            ids += on_hold_order_ids if @skip_on_hold
            ids += excluded_user_order_ids
            return ids.uniq
        end

        # TODO: Add tests
        def on_hold_order_ids
            ::OrderHold.all(fields: [ :order_id ]).on_hold.pluck(:order_id)
        end

        # TODO: Add tests
        def excluded_user_order_ids
            ::Order.all(user_id: EXCLUDED_USER_IDS).renting_rentals.pluck(:id)
        end
        
        def send_report_email!(amount_charged, orders_charged, orders_not_charged)
            #return if dry_run

            $LOG.info "Sending email report"
            if ReceiptMailer.new.send_customer_renewal_report(amount_charged, orders_charged, orders_not_charged, all_order_actions).deliver 
                $LOG.info "Email report sent"
            else
                $LOG.error "Error sending email report"
            end
        end

        # TODO: Add tests
        def all_order_actions
            excluded_orders = []
            
            excluded_user_order_ids.each do |o|
                excluded_orders << OpenStruct.new(
                    id:     o,
                    action: :skipped,
                    note:   'Excluded user',
                )
            end

            on_hold_order_ids.each do |o|
                excluded_orders << OpenStruct.new(
                    id:     o,
                    action: :skipped,
                    note:   'On hold',
                )
            end
            
            open_rental_orders.each do |order|
                oa = @order_actions.find{ |a| a[:id] == order.id } || {}
                excluded_orders << OpenStruct.new(
                    id:     order.id,
                    action: oa[:action],
                    note:   oa[:note],
                )
            end
            
            return excluded_orders.uniq{ |o| o.id }.sort{ |a,b| "#{a.action}#{a.note}#{a.id}" <=> "#{b.action}#{b.note}#{b.id}" } 
        end

        
        #
        # Compiles/charges an order to rent
        #
        # This class compiles the order lines for a rental order and then charges the sum total of the order lines.
        #
        # TODO: Add support for charge accounts - not currently being charged rent
        # TODO: Rename @order to @model
        #
        class Order
            attr_accessor :today, :dry_run, :compiled_lines, :skipped_because
            attr_reader :order, :to_charge, :subtotal, :tax, :damage_waiver, :card_receipt, :failure_reason, :card_model
            
            def initialize(order_model, today: nil, dry_run: false)
                @order = order_model
                @today = today || Time.zone.today
                @dry_run = dry_run
                @fees = []
            end

            def compile
                unless product_lines.any?
                    @skipped_because = "No valid product order lines"
                    $LOG.debug "No valid product lines for order: #{order.id}"
                    return false
                end

                unless shipped?
                    @skipped_because = "Not shipped"
                    $LOG.info "No products have shipped for order: #{order.id}"
                    return false
                end
                
                unless ready_for_renewal?
                    @skipped_because = "Within first billing cycle"
                    $LOG.info "No products to renew for order - within initial delivery window: #{order.id}"
                    return false
                end

                unless up_for_renewal?
                    @skipped_because = "Current cycle still open"
                    $LOG.info "No products to renew for order - billing cycle still open: #{order.id}"
                    return false
                end

                @compiled_lines = []
                product_lines.each do |line|
                    compiled_line = Rent::Order::Line.new(line, today: today, dry_run: dry_run).compile
                    next unless compiled_line

                    @compiled_lines << compiled_line
                    calculate_totals
                end

                return compiled_lines
            end

            def calculate_totals
                @to_charge = subtotal
                @to_charge += tax
                @to_charge += damage_waiver                
            end
            
            def subtotal
                @subtotal = compiled_lines.sum { |line| line[:total] }
            end

            def tax
                begin
                    @tax = subtotal * net_tax_rate
                rescue => error
                    $LOG.error "Error getting tax rate for order: %i | %s" % [ order.id, error.full_message ]
                    @tax = 0
                end
            end

            def net_tax_rate
                order.user.tax_exempt? ? 0 : order.tax_authority.total_rate
            end

            def damage_waiver
                begin
                    @damage_waiver = subtotal * (order.user.damage_waiver_exempt? ? 0 : ::Fee.damage_waiver)
                rescue => error
                    $LOG.error "Error getting damage waiver for order: %i | %s" % [ order.id, error.full_message ]
                    @damage_waiver = 0
                end
            end
            
            # NOTE: This will currently return true if any charge has been made for the order within the past
            #       SKIP_IF_CHARGED_WITHIN_DAYS constant. This isn't ideal since it'll skip billing if any
            #       other charge happened within the past two days.
            def already_charged?
                order.order_fees.all(:updated_at.gte => (today - SKIP_IF_CHARGED_WITHIN_DAYS.days).to_date).count > 0
            end

            # TODO: Add support for charge account charges - currently not applying rent to them
            # TODO: Refund charge if other stuff fails
            def charge!
                begin
                    card = credit_card_to_charge
                    unless card
                        $LOG.debug "Invalid card to charge for order: #{order.id}"
                        @failure_reason = "Invalid CC"
                        create_failed_transaction(reason: "No chargeable credit card") # unless dry_run
                        return false
                    end
                    
                    @card_receipt = card.charge!(to_charge) # unless dry_run
                    $LOG.info "Order charged: %i [card: %i, total: %.2f, customer: %s]" % [ order.id, card.model&.id, to_charge, order.user.email ]
                rescue => error
                    $LOG.debug "Order NOT charged: %i [total: %.2f, customer: %s] %s" % [ order.id, to_charge, order.user.email, error.full_message ]
                    @failure_reason = error.user_message rescue error.message
                    return false
                end

                begin
                    unless dry_run
                        $DB.transaction do
                            create_payment_log(card: card, receipt: card_receipt)
                            create_order_fee(card: card, receipt: card_receipt)
                            create_transaction
                        end
                    end
                rescue => error
                    $LOG.error "Card charged, but other error occurred while adding log entries: #{error.full_message}"
                    return false
                end

                return receipt
            end

            def receipt
                address = order.address
                return OpenStruct.new(
                    customer_email:        order.user.email,
                    customer_first_name:   order.user.first_name,
                    customer_last_name:    order.user.last_name,
                    order_id:              order.id,
                    project_name:          order.project_name,
                    site_name:             order.site&.name,
                    address:               "%s %s %s, %s. %s" % [ address&.address1, address&.address2, address&.city, address&.state, address&.zipcode ],
                    ordered_on:            order.ordered_on,
                    delivered_on:          initially_delivered_on,
                    order_lines:           compiled_lines.sort{ |a,b| a[:status] <=> b[:status] },
                    cycle_starts_on:       cycle_start,
                    cycle_ends_on:         cycle_end,
                    cycle_ends_on_display: cycle_end_display,
                    charged_on:            Time.zone.today.strftime('%B %-d, %Y'), 
                    subtotal:              subtotal,
                    tax:                   tax,
                    tax_exempt?:           order.user.tax_exempt?,
                    damage_waiver:         damage_waiver,
                    damage_waiver_exempt?: order.user.damage_waiver_exempt?, 
                    total:                 to_charge,
                    card_last_four:        @card_receipt&.last_four || card_model&.last_four,
                    card_pn_ref:           @card_receipt&.pn_ref,
                    card_auth:             @card_receipt&.authorization_code,
                    order_fee_id:          @order_fee_id,
                    failure_reason:        failure_reason,
                    dry_run?:              dry_run,
                )
            end
            
            def send_receipt_email!
                ReceiptMailer.new.send_customer_renewal_receipt(receipt).deliver
                $LOG.info "Email receipt sent to customer: %s [order: %i]" % [ order.user.email, order.id ]
            end

            # NOTE: Attempts to get a credit card to charge:
            #       - First attempts to charge card associated with order
            #       - Failing first step, it attempts to get user's default card
            #       - Failing that step, error out
            # TODO: Cleanup the logging
            def credit_card_to_charge
                order_card = order.credit_card
                if order_card
                    @card_model = order_card
                    begin
                        return ::SDN::Card.new(order.user).from_model(order_card)
                    rescue => error
                        $LOG.debug "Invalid credit card for order - trying user default card next: [order: %i, user: %s] %s" % [ order.id, order.user.email, error.message ]
                    end
                else
                    $LOG.debug "Order credit card NOT loaded - trying user default card next: [order: %i, customer: %s]" % [ order.id, order.user.email ]
                end
                
                user_default_card = order.user.default_credit_card
                if user_default_card
                    @card_model = user_default_card
                    begin
                        return ::SDN::Card.new(order.user).from_model(user_default_card)
                    rescue => error
                        $LOG.debug "Invalid default credit card for user - unable to charge renewal: [order: %i, user: %s] %s" % [ order.id, order.user.email, error.message ]
                        raise RuntimeError.new "No valid credit card for order: #{order.id}"
                    end
                else
                    $LOG.debug "User does not have a default card - order NOT charged: [order: %i, customer: %s]" % [ order.id, order.user.email ]
                    return false
                end
            end

            def create_payment_log(card:, receipt:)
                begin
                    log = PaymentLog.new(
                        user_id:         order.user_id,
                        payment_type_id: 2, # order_rental
                        stored_card_id:  card&.model&.id,
                        cc:              receipt&.last_four,
                        card_type:       receipt&.card_type,
                        cc_month:        card&.exp_month,
                        cc_year:         card&.exp_year,
                        price:           receipt&.amount,
                        auth_code:       receipt&.auth_code,
                        reference:       receipt&.pn_ref,
                        created_by_id:   ADMIN_USER_ID,
                    )

                    if dry_run
                        $LOG.info "Payment log entry created: DRY RUN [order: %i, card: %i, receipt: %s]" % [ order.id, card.model.id, receipt.inspect ]
                        return true
                    else
                        if log.save
                            $LOG.info "Payment log entry created: %i [order: %i, card: %i, receipt: %s]" % [ log.id, order.id, card.model.id, receipt.inspect ]
                            return @payment_log_id = log.id
                        else
                            $LOG.error "Payment log NOT created: %i [order: %i, card: %i, receipt: %s] %s" % [ order.id, card.model.id, receipt.inspect, log.errors.inspect ]                            
                        end
                    end
                rescue => error
                    $LOG.error "Payment log entry NOT created: [order: %i, card: %i, receipt: %s] %s" % [ order.id, card.model.id, receipt.inspect, error.full_message ]
                end

                return false
            end

            def create_order_fee(card:, receipt:)
                begin
                    fee = OrderFee.new(
                        order_id: order.id,
                        user_id: order.user.id,
                        charges: 0,
                        destage: 0,
                        shipping: 0,
                        waiver: damage_waiver,
                        tax: tax,
                        amount: receipt&.amount,
                        products: compiled_lines.map{ |line| [ line[:product_id], "#{line[:total]}" ] },
                        payment_id: @payment_log_id,
                    )

                    if dry_run
                        $LOG.info "Order fee entry created: DRY RUN [order: %i, card: %i, receipt: %s]" % [ order.id, card.model.id, receipt.inspect ]
                        return true
                    else
                        if fee.save
                            $LOG.info "Order fee entry created: %i [order: %i, card: %i, receipt: %s]" % [ fee.id, order.id, card.model.id, receipt.inspect ]
                            return @order_fee_id = fee.id
                        else
                            $LOG.error "Order fee NOT created: [order: %i, card: %i, receipt: %s] %s" % [ order.id, card.model.id, receipt.inspect, fee.errors.inspect ]                            
                        end
                    end
                rescue => error
                    $LOG.error "Order fee entry NOT created: [order: %i, card: %i, receipt: %s] %s" % [ order.id, card.model.id, receipt.inspect, error.full_message ]
                end

                return false
            end

            def create_failed_transaction(reason:)
                create_transaction(reason: reason, response: 'Failed')
            end
            
            def create_transaction(reason: nil, response: 'Processed')
                tx = Transaction.create(
                    response:           response,
                    failure_reason:     reason,
                    table_name:         'orders',
                    table_id:           receipt.order_id,
                    amount:             receipt.total.round(2),
                    tax:                receipt.tax.round(2),
                    type:               'Credit Card',
                    cc_last_four:       receipt.card_last_four,
                    transaction_number: receipt.card_pn_ref,
                    authorization_code: receipt.card_auth_code,
                    processed_by:       Rent::ADMIN_USER_ID,
                    processed_with:     'BillingRent'
                )

                if tx.saved?
                    $LOG.info "Transaction saved: #{tx.id}"
                    txd = TransactionDetail.create(transaction_id: tx.id, details: receipt.to_json)
                    if txd.saved?
                        $LOG.info "Transaction details saved: %i [tx: %i]" % [ txd.id, tx.id ]
                        return true
                    else
                        $LOG.error "Transaction details NOT saved: [tx: #{tx.id}]"
                        return false
                    end
                else
                    $LOG.error "Transaction NOT saved: [order: %i, receipt: %s] %s" % [ order.id, receipt.inspect, tx.errors.inspect ]
                    return false
                end
            end

            # Extra fee line for future manual billing
            # TODO: Write tests
            def create_failed_billing_record
                description = "Rent for #{cycle_start&.strftime('%D')} - #{cycle_end_display&.strftime('%D')}"
                bprice = (subtotal).to_f.round(4)
                price = (bprice + tax).to_f.round(4)
                
                ol_furniture = ::OrderLine.create(
                    order_id:    order.id,
                    base_price:  bprice,
                    price:       price,
                    description: description,
                )

                if ol_furniture.saved?
                    $LOG.info "Failed renewal order line saved: #{ol_furniture.id}"
                    ef = ::ExtraFee.create(
                        order_id:      order.id,
                        type:          'Renewal',
                        description:   description,
                        tax:           net_tax_rate * 100,
                        order_line_id: ol_furniture.id,
                        charged_by:    ADMIN_USER_ID,
                    )
                    if ef.saved?
                        $LOG.info "Failed renewal extra fee saved: #{ef.id}"

                        if damage_waiver > 0
                            dw_description = "Waiver for #{cycle_start&.strftime('%D')} - #{cycle_end_display&.strftime('%D')}"
                            ol_waiver = ::OrderLine.create(
                                order_id:    order.id,
                                base_price:  damage_waiver.to_f.round(4),
                                price:       damage_waiver.to_f.round(4),
                                description: dw_description,
                            )

                            if ol_waiver.saved?
                                $LOG.info "Failed renewal damage waiver order line saved: #{ol_waiver.id}"

                                ef_waiver = ::ExtraFee.create(
                                    order_id:      order.id,
                                    type:          'Renewal Damage Waiver',
                                    description:   dw_description,
                                    tax:           0,
                                    order_line_id: ol_waiver.id,
                                    charged_by:    ADMIN_USER_ID,
                                )
                                if ef_waiver.saved?
                                    $LOG.info "Failed renewal damage waiver extra fee saved: #{ef_waiver.id}"
                                    return true
                                else
                                    $LOG.error "Failed renewal damage waiver extra fee NOT saved: [line: #{ol_waiver.id}] #{ef_waiver.errors.inspect}"
                                    return false
                                end
                            end
                        else
                            return true
                        end
                    else
                        $LOG.error "Failed renewal extra fee NOT saved: [line: #{ol_furniture.id}] #{ef.errors.inspect}"
                        return false
                    end
                else
                    $LOG.error "Failed renewal line NOT saved: [order: #{order.id}] #{ol.errors.inspect}"
                    return false
                end
            end

            # Have any order lines shipped yet?
            def shipped?
                order.shipped?
            end

            def up_for_renewal?
                ready_for_renewal? and days_since_renewal_start % Rent::BILLING_INTERVAL_DAYS == 0
            end

            # Have enough days passed since order's initial charge so that it's ready to be renewed?
            def ready_for_renewal?
                days_since_renewal_start >= 0
            end
            
            def days_since_renewal_start
                (today - renewals_start_on).to_i
            end

            # 
            def renewals_start_on  
                initially_delivered_on + Rent::INITIAL_DAYS_CHARGED.days + Rent::BILLING_INTERVAL_DAYS.days rescue nil
            end

            def initially_delivered_on
                ::Order.initial_ship_date(order.id)&.to_date
            end

            def product_lines
                order.order_lines.product_lines # Use #all_product_lines when it's time to include voided lines again
            end

            def cycle_start
                today - Rent::BILLING_INTERVAL_DAYS.days
            end

            def cycle_end
                today
            end
            
            def cycle_end_display
                cycle_end - 1.day # 5/1 + 7.days = 5/8, which appears to be 8 days when being inclusive of both dates                
            end
                
            def compiled_lines
                @compiled_lines ||= compile
            end
            
            
            #
            # Handles compiling an order line's rent to charge
            #
            # NOTE: Currently using `base_price` to determine what to charge. `price` can't be trusted to include correct
            #       taxes. This means taxes will need to be calculated.
            #
            class Line
                attr_accessor :today, :dry_run, :delivered_on, :added_to_order_on, :voided_on, :returned_on, :product_owner_id,
                              :order_customer_id, :cycle_start, :cycle_end, :applied_blackout_dates
                attr_reader :line, :to_charge, :chargeable_days

                def initialize(line, today: nil, dry_run: false)
                    raise ArgumentError.new "Invalid order line supplied: #{line.inspect}" unless line

                    @line = line
                    @today = today
                    @dry_run = dry_run
                    @to_charge = 0.to_d
                    @chargeable_days = 0
                    @cycle_start = today - Rent::BILLING_INTERVAL_DAYS.to_i
                    @cycle_end = today
                    @applied_blackout_dates = []
                end

                def compile
                    unless delivered? or (voided? and days_held > 0 and first_renewal?)
                        $LOG.info "Order line skipped - not delivered/voided: #{line.id}"
                        return
                    end

                    calculate_fees unless rented_by_owner?
                    
                    return {
                        type:             'product',
                        product_id:       line.product_id,
                        product_name:     line.product.name,
                        product_rent:     line.product.rent_per_month,
                        total:            to_charge.round(2),
                        cycle_start:      cycle_start,
                        cycle_end:        cycle_end,
                        added_to_order:   added_to_order_on,
                        delivered:        delivered_on,
                        voided_on:        voided_on,
                        extra_days:       first_renewal? ? days_held : 0,
                        total_days:       chargeable_days,
                        daily_rent:       daily_rent,
                        blackout_dates:   applied_blackout_dates,
                        returned_on:      returned_on,
                        dates_held:       dates_held,
                        status:           returned? ? 'Returned' : voided? ? 'Void' : 'Renting',
                        rented_by_owner:  rented_by_owner?,
                        is_first_renewal: first_renewal?,
                    }
                end
                
                def calculate_fees
                    add_holding_fees
                    add_rental_fees
                    subtract_blackout_date_fees

                    return to_charge
                end

                def add_holding_fees
                    return unless first_renewal?
                    
                    @to_charge += amount = days_held * daily_rent
                    @chargeable_days += days_held

                    $LOG.info "First renewal for line: %i [added to order: %s, delivered: %s, days held: %i, holding charge: %.2f]" % [ line.id, added_to_order_on, delivered_on, days_held, amount ]
                end

                # TODO: More tests for voided 
                def dates_held
                    return [] unless added_to_order_on and (delivered? or voided?)
                    
                    date = added_to_order_on + Rent::GRACE_PERIOD_DAYS.days
                    dates_held = []

                    bound = delivered_on || voided_on
                    while date < bound
                        dates_held << date
                        date += 1.day
                    end

                    return dates_held
                end
                
                # Days held over grace period and before delivery
                def days_held
                    return dates_held.count
                end

                def add_rental_fees
                    return if voided?
                    if returned?
                        add_early_return_rental_fees
                        return
                    end

                    @chargeable_days += Rent::BILLING_INTERVAL_DAYS
                    @to_charge += amount = Rent::BILLING_INTERVAL_DAYS * daily_rent

                    $LOG.info "Renewal for line: %i [added to order: %s, delivered: %s, chargeable days: %i, charge: %.2f]" % [ line.id, added_to_order_on, delivered_on, BILLING_INTERVAL_DAYS, amount ]                   
                end

                def add_early_return_rental_fees
                    return unless returned? and returned_within_cycle?
                    
                    @cycle_end = returned_on
                    @chargeable_days += days_to_charge = Rent::BILLING_INTERVAL_DAYS - days_since_returned
                    @to_charge += amount = days_to_charge * daily_rent                    

                    $LOG.info "Last renewal for line: %i [added to order: %s, delivered: %s, returned: %s, chargeable days: %i, charge: %.2f]" % [ line.id, added_to_order_on, delivered_on, returned_on, chargeable_days, amount ]                    
                end

                # NOTE: Date range includes start, but doesn't include end date.
                def subtract_blackout_date_fees
                    return unless Rent::BLACKOUT_DATES&.any?

                    blackout_dates = Rent::BLACKOUT_DATES
                    blackout_dates.each do |period|
                        period = { start: period, end: period } if period.is_a?(String)
                        period = { start: period[:start].to_date, end: period[:end].to_date } rescue {}
                        date = cycle_start
                        days = 0
                        while date < cycle_end
                            if date >= period[:start] and date < period[:end]
                                @to_charge -= daily_rent if @to_charge > 0
                                @chargeable_days -= 1 if @chargeable_days > 0
                                @applied_blackout_dates << date if @chargeable_days > 0
                                days += 1
                            end
                            date += 1.day
                        end
                        $LOG.info "Blackout dates applied for line: %i [days subtracted: %i, start: %s, end: %s]" % [ line.id, days, period[:start], period[:end] ] if days > 0
                    end
                end
                
                def first_renewal?
                    days_since_renewal_start == 0
                end
                
                def days_since_renewal_start
                    (today - renewals_start_on).to_i rescue nil
                end

                def renewals_start_on
                    delivered_on + Rent::INITIAL_DAYS_CHARGED.days + Rent::BILLING_INTERVAL_DAYS.days rescue nil
                end

                def rented_by_owner?
                    product_owner_id.present? and product_owner_id == order_customer_id rescue false
                end
                
                def delivered?
                    delivered_on.present?
                end
                
                def delivered_on
                    @delivered_on ||= line.shipped_at&.to_date
                end

                def voided?
                    voided_on.present?
                end
                
                def voided_on
                    @voided_on ||= line.voided_on&.to_date
                end

                def days_since_added_to_order
                    (today - added_to_order_on).to_i rescue nil
                end
                
                def added_to_order_on
                    @added_to_order_on ||= line.created_at&.to_date
                end

                def daily_rent
                    (line.base_price / 30).ceil(3)
                end

                def returned_within_cycle?
                    returned? && days_since_returned < Rent::BILLING_INTERVAL_DAYS
                end
                
                def returned?
                    returned_on.present?
                end

                def days_since_returned
                    (today - returned_on).to_i rescue nil
                end

                def returned_on
                    @returned_on ||= line.returned_at&.to_date
                end

                def product_owner_id
                    @product_owner_id ||= line.product&.customer_id rescue nil
                end

                def order_customer_id
                    @order_customer_id ||= line.order&.user_id rescue nil
                end
            end
        end
        
    end
    
end

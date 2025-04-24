class ReceiptMailer < ApplicationMailer

    default from: 're|SOLVED <support@r-e-solved.com>'
    default to: 'support@r-e-solved.com'

    # const_def :PHX_ORDERS,     'orders-phx@sdninc.net'
    # const_def :PHX_SCHEDULING, 'scheduling-phx@sdninc.net'
    # const_def :SEA_ORDERS,     'orders-sea@sdninc.net'
    # const_def :SEA_SCHEDULING, 'scheduling@sdninc.net'

    def send_customer_order_receipt(user, receipt)
        @receipt = receipt
        @orders = @receipt.orders.processed

        @user = OpenStruct.new(email: user.email, first_name: user.first_name)

        @summary = OpenStruct.new(
            ordered_date: @orders.first.ordered_date,
            delivery_date: @orders.first.due_date,
            delivery_address: @orders.first.address,
            delivery?: @orders.first.service == 'Company',
        )

        @orders = @orders.map do |order|
            OpenStruct.new(
                id:               order.id,
                type:             order.order_type,
                location:         order.site.name,
                ordered_date:     order.ordered_date,
                delivery_date:    order.due_date,
                delivery?:        order.service == 'Company',
                delivery_address: order.address,
                products:         order.order_lines.select{ |ol| ol.product.present? }.map{ |ol| OpenStruct.new(
                    id:        ol.product.id,
                    name:      ol.product.name,
                    image_url: ol.product.main_image&.url,
                    price:     ol.price,
                )},
            )
        end

        subject = "New %s: %s" % [ "Order".pluralize(@orders.size), @orders.pluck(:id)&.join(', ') ]

        # sdnto = @orders.first.location == 'Phoenix' ? PHX_ORDERS : SEA_ORDERS

        mail(to: @user.email, cc: 'support@r-e-solved.com', subject: subject, template_name: "customer_order_receipt")
    end

    def send_customer_add_to_order_receipt(order, products)
        @order = order
        @products = products.to_a
        
        subject = "Order %i Updated - Product(s) Added" % [ @order.order_id ]
        mail(to: @order.user.email, cc: 'support@r-e-solved.com', subject: subject, template_name: "customer_add_to_order_receipt")
    end

    # Sends receipt for rental renewal
    def send_customer_renewal_receipt(receipt)
        @receipt = receipt
        @failed = !!receipt.failure_reason

        if @failed
            subject = "Renewal Failed for Order: %s"
        else
            subject = "Renewal Receipt for Order: %s"
        end
        
        if @receipt.dry_run?
            subject = "[TEST - #{@receipt.cycle_ends_on&.strftime('%D')}] " + subject
            to = "support@r-e-solved.com"
            bcc = nil
        else
            to = @receipt.customer_email
            
        end
            
        subject = subject % [ @receipt.order_id ]

        mail(to: to, cc: 'support@r-e-solved.com', subject: subject, template_name: "customer_renewal_receipt")
    end

    # TODO: Move this to its own "alert" mailer or something equivalent
    def send_customer_renewal_report(amount_charged, orders_charged, orders_not_charged, all_order_actions)
        @amount_charged = amount_charged
        @orders = { fail: orders_not_charged, success: orders_charged, }
        @all_order_actions = all_order_actions

        order_with_cycle = @orders[:success].any? ? @orders[:success].first : @orders[:fail].first
        @cycle_start = order_with_cycle.receipt.cycle_starts_on
        @cycle_end = order_with_cycle.receipt.cycle_ends_on_display
        
        subject = "Renewals for %s: %i failures" % [ Date.today.strftime('%D'), @orders[:fail].count ]
        mail(to: ["support@r-e-solved.com"], cc: 'support@r-e-solved.com', subject: subject, template_name: "admin_renewal_report")
    end

    def send_customer_cancellation_confirmation(order)
        @order = order
        subject = "Order #{@order.order_id} Cancelled"
        mail(to: @order.user.email, cc: 'support@r-e-solved.com', subject: subject, template_name: "customer_cancel_order_confirmation")
    end

    def send_admin_cancellation_confirmation(order, voided_by)
        @order = order
        @voided_by = voided_by
        subject = "Order #{@order.order_id} Cancelled"
        # sdnto = order.model.site_id == 25 ? PHX_ORDERS : SEA_ORDERS
        mail(to: @order.user.email, cc: 'support@r-e-solved.com', subject: subject, template_name: "admin_cancel_order_confirmation")
    end

    def send_destage_request(order:, date:, requested_by:, expedited: false, siblings: [])
        @order = order
        @date = date.to_date
        @requested_by = requested_by
        @expedited = expedited
        @siblings= siblings
        @customer_first_name = @order.model.user.first_name rescue nil
        # sdnto = order.model.site_id == 25 ? PHX_SCHEDULING : SEA_SCHEDULING
        subject = "Destage Request: Order #{@order.order_id}"
        mail(to: [@order.user.email], cc: 'support@r-e-solved.com', subject: subject, template_name: "destage_request_confirmation")
    end

    def send_ihs_receipt(stuff)

    end
end

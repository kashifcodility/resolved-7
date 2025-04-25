# app/services/stripe_invoice_service.rb

class StripeInvoiceService
    def initialize(user, order)
      @user = user.owner.present? ? user.owner : user
      @order = order
    #   @idempotency_key = idempotency_key
    end
  
    # Create a Stripe invoice for the given order and customer data
    def create_invoice(recurring_invoice)
      customer = retrieve_customer
      invoice = create_stripe_invoice(customer, recurring_invoice)
  
      add_invoice_items(invoice.id, customer.id, recurring_invoice)
      local_db_invoice = Invoice.where(order_id: @order.id)&.last
      local_db_invoice.update(stripe_invoice_id: invoice.id) if local_db_invoice.present?
      invoice
    end

    # Add new items to an existing invoice
    def update_invoice(lines, invoice_id)
      invoice = Stripe::Invoice.retrieve(invoice_id)
      customer = retrieve_customer
      # Add new items to the invoice
      if invoice.status == 'draft'
        lines.each do |ol|
          price_in_cents = (ol&.price * 100).to_i.to_s
          create_invoice_item(ol.quantity, price_in_cents, ol&.product&.product, invoice_id, customer.id) 
        end  
      else
        Rails.logger.info "Invoice is already finalized and cannot be updated"
      end  
      
      # Return the updated invoice
      Stripe::Invoice.retrieve(invoice_id)
    end

    def delete_invoice_item(product_name, invoice_id)
      invoice = Stripe::Invoice.retrieve(invoice_id)

      # Iterate over the invoice items to find the one with the matching description
      invoice.lines.data.each do |line_item|
        if line_item.description == product_name
          # Delete the invoice item based on its ID
          line_item_to_remove = Stripe::InvoiceItem.retrieve(line_item.id)
          line_item_to_remove.delete

          puts "Removed Line Item: #{line_item.id}"
        end
      end if invoice.present? && invoice.status == 'draft'

    end  
  
    private
  
    def retrieve_customer
      # Retrieve the customer from Stripe using the given Stripe ID
      Stripe::Customer.retrieve(@user.stripe_customer_id)
    end
  
    def create_stripe_invoice(customer, recurring_invoice)
      new_stripe_doc_number = ''
      if recurring_invoice == true && Rails.env != "development"
        invoice_db = Invoice.where(order_id: @order&.id)&.last
        stripe_doc_number = invoice_db.stripe_doc_number&.split('-')&.last if invoice_db.present?
        if stripe_doc_number.present?
          new_qbo_id = (stripe_doc_number.to_i + 1).to_s
          new_stripe_doc_number = "#{@order.id}-#{new_qbo_id}"
          # invoice.doc_number = new_stripe_doc_number     
        else
          new_stripe_doc_number = "#{@order.id}-#{1}"
          # invoice.doc_number = new_stripe_doc_number 
        end    
      else
        if Rails.env == "development"
          new_stripe_doc_number = "#{@order.id}-dev"
        else
          new_stripe_doc_number = @order.id
        end        
      end
      last_invoice = @order.invoices&.last
      last_invoice.update(stripe_doc_number: new_stripe_doc_number) if last_invoice.present? && 
                                                                       recurring_invoice == true
      # Create a new invoice for the customer
      Stripe::Invoice.create({
        customer: customer.id,
        auto_advance: true,  
        description: "Invoice for Order ##{@order.id}",
        metadata: { order_id: new_stripe_doc_number.to_s }
      }, { idempotency_key: Rails.env == "development" ? "#{new_stripe_doc_number.to_s}-dev-#{rand(1000)}" : new_stripe_doc_number.to_s })
    end
  
    def add_invoice_items(invoice_id, customer_id, recurring_invoice)
      # Iterate through each item in the order and add it to the invoice
      @order.order_lines.each do |ol|
        # only for items in rent recurring invoice
        price_in_cents = (ol&.price * 100).to_i.to_s
        if recurring_invoice == true          
          create_invoice_item(ol.quantity, price_in_cents, ol&.product&.product, invoice_id, customer_id) if ol.line_type == "rent"
        else
          create_invoice_item(ol.quantity, price_in_cents, ol&.product&.product, invoice_id, customer_id) # execute for intent buy & rent both
        end    
      end


      if @order.rush_order == true && recurring_invoice == false
        price_in_cents = (Order.default_rush_order_fee * 100).to_i.to_s
        create_invoice_item(1, price_in_cents, "Rush order fee", invoice_id, customer_id)
      end

        price_in_cents = ((@order.service == "pickup" ? 0.0 : Order.default_shipping_fee) * 100).to_i.to_s
        create_invoice_item(1, price_in_cents, "Shipping fee", invoice_id, customer_id) if recurring_invoice == false
    end
  
    def create_invoice_item(quantity, price_in_cents, product_name, invoice_id, customer_id)
      # Create an invoice item for the specified product
      Stripe::InvoiceItem.create({
        customer: customer_id,
        currency: 'usd',
        description: product_name,
        invoice: invoice_id,
        quantity: quantity,
        unit_amount_decimal: price_in_cents # amount in cents
      })
    end
  end
  
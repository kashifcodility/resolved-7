module QuickbooksOauth 
  extend ActiveSupport::Concern
  
  def oauth_access_token
    intuit_account = IntuitAccount.last          
      if Time.current.utc < intuit_account.oauth2_access_token_expires_at
          access_token = OAuth2::AccessToken.new(oauth2_client, intuit_account.oauth2_access_token, refresh_token: intuit_account.oauth2_refresh_token)
      else
          access_token = OAuth2::AccessToken.new(oauth2_client, intuit_account.oauth2_access_token, refresh_token: intuit_account.oauth2_refresh_token)
          token = access_token.refresh!
            IntuitAccount.update(
              oauth2_access_token: token.token,
              oauth2_refresh_token: token.refresh_token,
              oauth2_access_token_expires_at: Time.current.utc + 1.hour,
              oauth2_refresh_token_expires_at: 100.days.from_now
            )
          access_token = OAuth2::AccessToken.new(oauth2_client, token.token, refresh_token: token.refresh_token)
      end
    
  end  


  def oauth2_client 
    options = { site: 'https://appcenter.intuit.com/connect/oauth2', 
                authorize_url: "https://appcenter.intuit.com/connect/oauth2", 
                token_url: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer" }
    Quickbooks.sandbox_mode = Rails.env.development? ? true : false 
    OAuth2::Client.new(ENV['OAUTH_CLIENT_ID'], ENV['OAUTH_CLIENT_SECRET'], options) 

  end

  class_methods do

    def create_invoice_items(invoice, amount, type, detail, quantity)
      line_item = Quickbooks::Model::InvoiceLineItem.new
      line_item.description = detail
      calculated_amount = amount * quantity
      line_item.amount = calculated_amount
      line_item.detail_type = 'SalesItemLineDetail'
      line_item.sales_line_item_detail = Quickbooks::Model::SalesItemLineDetail.new
      line_item.sales_line_item_detail.unit_price = amount
      line_item.sales_line_item_detail.quantity = quantity

      if type == "rush order"  
        line_item.sales_line_item_detail.item_ref = Quickbooks::Model::BaseReference.new(20) if Rails.env == "development"
        line_item.sales_line_item_detail.item_ref = Quickbooks::Model::BaseReference.new(1010000081) unless Rails.env == "development"
      elsif type == "shipping fee"
        line_item.sales_line_item_detail.item_ref = Quickbooks::Model::BaseReference.new(21) if Rails.env == "development"
        line_item.sales_line_item_detail.item_ref = Quickbooks::Model::BaseReference.new(1010000091) unless Rails.env == "development"
      elsif type == "rent"  
        line_item.sales_line_item_detail.item_ref = Quickbooks::Model::BaseReference.new(19) if Rails.env == "development"
        line_item.sales_line_item_detail.item_ref = Quickbooks::Model::BaseReference.new(4) unless Rails.env == "development"
      else
        line_item.sales_line_item_detail.item_ref = Quickbooks::Model::BaseReference.new(10)   if Rails.env == "development"
        line_item.sales_line_item_detail.item_ref = Quickbooks::Model::BaseReference.new(1010000001)   unless Rails.env == "development"
      end   

      # line_item.sales_line_item_detail.description = detail
      invoice.line_items << line_item
    end
    
    def create_quickbooks_customer(order_user) 
      intuit_account = IntuitAccount.last
      user = order_user&.owner.present? ? order_user.owner : order_user
      if intuit_account.present? 
        token = IntuitAccount.new.oauth_access_token 
        service = Quickbooks::Service::Customer.new 
        service.access_token = token 
        service.realm_id = intuit_account.realm_id
        qb_customer = Quickbooks::Model::Customer.new 
        qb_customer.given_name = user.first_name 
        qb_customer.family_name =  user.last_name
        qb_customer.display_name = user.username #should unique 
        qb_customer.email_address = user.email
        begin
          customers = service.query("SELECT * FROM Customer WHERE DisplayName = '#{user.username}' ")
          if customers.entries.count > 0
            customer = customers.entries.first
            customer_id = customer.id
          else
            customer = service.create(qb_customer)
            customer_id = customer.id
          end
          # flash[:notice] = "Customer successfully created on QuickBooks with ID: #{customer.id}" 
        rescue Quickbooks::Forbidden => e 
          Rails.logger.error("QuickBooks Authorization Failed: #{e.message}") 
          # flash[:alert] = "Authorization failed. Please reconnect your QuickBooks account." 
        rescue Quickbooks::InvalidModelException => e 
          # flash[:alert] = "Failed to create customer on QuickBooks: #{e.message}" 
        end
      end
    end

    def create_quickbooks_invoice(order_id, quickbooks_customer_id, recurring_invoice)  

      intuit_account = IntuitAccount.last
      order = Order.find(order_id)
    
      token = IntuitAccount.new.oauth_access_token 
      
      
      service = Quickbooks::Service::Invoice.new
      service.access_token = token 
      service.realm_id = intuit_account.realm_id

      total = 0.00
      total_invoice = 0.0
      invoice = Quickbooks::Model::Invoice.new
      order.order_lines.each do |ol|
        if ol.line_type == 'rent'
          product = ol.product
          if recurring_invoice == true
            product_piece = ProductPiece.first(order_line_id: ol.id, status: 'Renting')
            # binding.pry
            total_invoice += ol&.price.to_f.round(2) if product_piece.present? 
            create_invoice_items(invoice, ol&.price.to_f.round(2), "rent", product.product, ol.quantity)  if product_piece.present? 
          else
            total_invoice += ol&.price.to_f.round(2) 
            create_invoice_items(invoice, ol&.price.to_f.round(2), "rent", product.product, ol.quantity)          
          end          
        else
          if recurring_invoice == false
            product = ol.product
            total_invoice += product&.sale_price.to_f.round(2)
            create_invoice_items(invoice, product&.sale_price.to_f.round(2), "buy", product.product, ol.quantity)
          end
        end    
      end

      if order.rush_order == true && recurring_invoice == false
        total_invoice += Order.default_rush_order_fee.round(2)
        create_invoice_items(invoice, Order.default_rush_order_fee.round(2), 'rush order', 'rush order', 1)
      end  

      if order.service == "Company" && recurring_invoice == false
        total_invoice += Order.default_shipping_fee.round(2)
        create_invoice_items(invoice, Order.default_shipping_fee.round(2),'shipping fee', 'shipping fee', 1)
      end
      user = order.user.owner.present? ? order.user.owner : order.user
      # qbo_doc_number = ''
      new_qbo_doc_number = ''
      # set customer reference
      customer_ref = Quickbooks::Model::BaseReference.new
      customer_ref.name = order.user.username
      customer_ref.value = quickbooks_customer_id
      invoice.customer_ref = customer_ref
      invoice.bill_email = Quickbooks::Model::EmailAddress.new(order&.user&.email) 
      # Create the invoice
      invoice.txn_date = Date.today
      invoice.due_date = order.due_date
      if recurring_invoice == true && Rails.env != "development"
        invoice_db = Invoice.last(order_id: order&.id)
        qbo_doc_number = invoice_db.qbo_doc_number&.split('-')&.last if invoice_db.present?
        if qbo_doc_number.present?
          new_qbo_id = (qbo_doc_number.to_i + 1).to_s
          new_qbo_doc_number = "#{order.id}-#{new_qbo_id}"
          invoice.doc_number = new_qbo_doc_number     
        else
          new_qbo_doc_number = "#{order.id}-#{1}"
          invoice.doc_number = new_qbo_doc_number 
        end    
      else
        if Rails.env == "development"
          invoice.doc_number = "#{order.id}-dev11"
        else
          invoice.doc_number = order.id
        end    
        
      end  
      invoice.total = total
      custom_field = Quickbooks::Model::CustomField.new
      custom_field.name = "Project Name" 
      custom_field.string_value = order.project_name
      custom_field.id = '1'
      custom_field.type = "StringType"
      invoice.custom_fields << custom_field

      
      location = Quickbooks::Model::CustomField.new
      location.name = "Location"
      location.string_value = "Site (Refurnish)"
      location.id = '5'
      location.type = "StringType"
      invoice.custom_fields << location


      
      shipping_address = Quickbooks::Model::PhysicalAddress.new
      shipping_address.line1 = order.address.address1
      shipping_address.city = order.address.city
      shipping_address.country_sub_division_code = "USA" # State or region code
      shipping_address.postal_code = order.address.zipcode
      shipping_address.country = order.address.country.name
      
      # Create billing address
      billing_address = Quickbooks::Model::PhysicalAddress.new
      billing_address.line1 = order.billing_address.address1
      billing_address.city = order.billing_address.city
      billing_address.country_sub_division_code = "USA" # State or region code
      billing_address.postal_code = order.billing_address.zipcode
      billing_address.country = order.billing_address.country.name
      
      # Assign addresses to the invoice
      invoice.shipping_address = shipping_address
      invoice.billing_address = billing_address

      # Send invoice to QuickBooks
      begin
        created_invoice = service.create(invoice)
        invoice = Invoice.create(qbo_invoice_id: created_invoice.id, invoice_total: total_invoice, 
                       order_id: order.id, status: 'Pending', user_id: order.user.id,created_by: order.user.id, 
                       edited_by: order.user.id, qbo_doc_number: new_qbo_doc_number)
        puts invoice.inspect+"===================="  
        create_dispatch_track_order(order)               
        puts "Invoice successfully created with ID: #{created_invoice.id}"
      rescue Quickbooks::InvalidModelException => e
        puts "Failed to create invoice: #{e.message}"
      end
    end

    def update_quickbooks_invoice(qbo_invoice_id, new_lines)

      intuit_account = IntuitAccount.last
      # order = Order.find(order_id)
    
      token = IntuitAccount.new.oauth_access_token
      
      # Initialize the QuickBooks Invoice service
      service = Quickbooks::Service::Invoice.new
      service.access_token = token
      service.realm_id = intuit_account.realm_id

      begin
        # Fetch the existing invoice using its ID
        invoice = service.fetch_by_id(qbo_invoice_id)  # Use the stored QuickBooks invoice ID

        total = 0.00
        total_invoice = 0.0
        # invoice = Quickbooks::Model::Invoice.new
        new_lines.each do |ol|
          if ol.line_type == 'rent'
            product = ol.product
            total_invoice += ol&.price.to_f.round(2)
            create_invoice_items(invoice, ol&.price.to_f.round(2), "rent", product.product, ol.quantity)        
          else
            product = ol.product
            total_invoice += product&.sale_price.to_f.round(2)
            create_invoice_items(invoice, product&.sale_price.to_f.round(2), "buy", product.product, ol.quantity)        
          end    
        end unless new_lines.blank?
    
        # Update the invoice on QuickBooks
        updated_invoice = service.update(invoice)
    
      rescue Quickbooks::InvalidModelException => e
        puts "Failed to update invoice: #{e.message}"
      end
    end
    
 
    def delete_quickbooks_invoice(invoice_id)
      token = IntuitAccount.new.oauth_access_token 
      service = Quickbooks::Service::Invoice.new
      service.access_token = token 
      service.company_id = IntuitAccount.last&.realm_id    
      
      invoice_id = invoice_id            
      invoice = service.fetch_by_id(invoice_id)
      service.delete(invoice) if invoice.present?

    end

    def delete_quickbooks_line_item_from_invoice(product_name, invoice_id)
      token = IntuitAccount.new.oauth_access_token 
      service = Quickbooks::Service::Invoice.new
      service.access_token = token 
      service.company_id = IntuitAccount.last&.realm_id    
                 
      invoice = service.fetch_by_id(invoice_id)
      if invoice.present?
        invoice.line_items.reject!{|li| li.description == product_name}
        service.update(invoice)
      end  
    end

    def create_dispatch_track_order(order)
      items = []
      notes = []
      order.order_lines.each do |ol|
        items << {
          sale_sequence: 1,
          item_id: ol.product.sku,
          description: ol.product.product,
          quantity: ol.quantity,
          location: ol.room.name,
          cube: "3.5", #it is volume
          setup_time: "1",
          weight: "2.5",
          length: '12',
          price: ol&.price.to_f.round(2),
          countable: true,
          
          }
      
      end  
  
      if order.rush_order == true
        items <<  {
            sale_sequence: 1,
            item_id: "SKU-rush-order",
            description: "Rush order charges",
            quantity: 1,
            setup_time: "1",
            price: Order.default_rush_order_fee.round(2)
          }
      end
      
      if order.service == "Company"
        items <<  {
            sale_sequence: 1,
            item_id: "SKU-shipping",
            description: "Shipping charges",
            quantity: 1,
            setup_time: "1",
            price: Order.default_shipping_fee.round(2)
        }
      end
      
      order_data = {
        order_number: order.id,
        service_type: order.service == "Company" ? "Stage Delivery" : "Will Call Pick Up" ,
        customer: {
            id: order.user.id,
            first_name: order.user.first_name,
            last_name: order.user.last_name,
            email: order.user.email,
            phone1: order.user.mobile,
            phone2: order.user.telephone,
            address1: order.address.address1,
            address2: order.address.address2,
            city: order.address.city,
            state: order.address.state,
            zip: order.address.zipcode,
            preferred_contact_method: "EMAIL"
        },
        delivery_date: order.due_date.strftime("%Y-%m-%d"),
        request_delivery_date: order.due_date.strftime("%Y-%m-%d"),
        items: items,
        additional_fields: {
          project_name: order.project_name,
          order_link: "https://www.r-e-solved.com/account/orders/#{order.id}",
        },
  
      }
      
      DispatchTrackService.import_order(order_data)  
    end

  end





end
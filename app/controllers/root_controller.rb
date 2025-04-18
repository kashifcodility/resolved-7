require 'sdn/cart'
class RootController < ApplicationController

    # We are not the main application yet.  Choices here are:
    #
    # (1) Render something in its place, to catch root (/) requests
    # (2) Auto-redirect root (/) requests to www.r-e-solved.com
    # (3) GFY
    #
    # For now, we'll do (1) as an index of things this app serves up.
    #
    # NOTE: Our gradual integration strategy involves serving one or more
    # subdirs in the SDN URL hierarchy, while PHP serves the main ones.  When
    # that day arrives, visit the following site for instructions how to do it.
    #
    # http://stevesaarinen.com/blog/2013/05/16/mounting-rails-in-a-subdirectory-with-nginx-and-unicorn/
    # https://timlentse.github.io/2015/12/06/How-to-mount-a-rails-app-in-a-subdirectory-with-NGINX.html

    def index
        binding.pry
        if params[:auth_user_id].present? && params[:auth_code].present?
           user = User.first(id: params[:auth_user_id])
           user_authentication = UserAuthentication.last(user_id: params[:auth_user_id])
           if user.present? && user_authentication.present?
            session[:user_id] = user.id
            session[:auth_code] = user_authentication.auth_code
            session[:site_id] = user.site&.id || DEFAULT_SITE_ID
            flash.notice = "Logged in!"
            return redirect_to plp_path
           end 
           
        end    
        cart_items = eval(current_user&.cart&.items) if current_user&.cart&.present?
        cart_items.each do |item|
            product = Product.find(item[:id])   
            if product.quantity == 0
                begin
                    @cart.remove_items(product.id)
                    flash[:notice] = "Deleted #{product.name} due to unavailability from cart."
                rescue Exception => e
                    flash.alert = e.message
                end
            end    
        end if cart_items.present? # delete those products if not available now from cart.

        @main_heading               = get_cms_fields('homepage', 'main_heading')
        @main_description           = get_cms_fields('homepage', 'main_description')
        @heading_1                  = get_cms_fields('homepage', 'heading_1')
        @heading_2                  = get_cms_fields('homepage', 'heading_2')
        @description_1              = get_cms_fields('homepage', 'description_1')
        @description_2              = get_cms_fields('homepage', 'description_2')
        @feedback_main              = get_cms_fields('homepage', 'feedback_main')
        @feedback_heading_1         = get_cms_fields('homepage', 'feedback_heading_1')
        @feedback_heading_2         = get_cms_fields('homepage', 'feedback_heading_2')
        @feedback_heading_3         = get_cms_fields('homepage', 'feedback_heading_3')
        @feedback_description_1     = get_cms_fields('homepage', 'feedback_description_1')
        @feedback_description_2     = get_cms_fields('homepage', 'feedback_description_2')
        @feedback_description_3     = get_cms_fields('homepage', 'feedback_description_3')
        render
    end

    def add_items_to_order      #from order show page
        selected_products = JSON.parse(params[:product_ids])
        products = []
        product_ids = []
        order_model = Order.find(params[:order_id])
        order = ::Sdn::Order.from_model(order_model)
        selected_products.each do |action, quantity, product_id|
          product = Product.where(id: product_id)&.first
          product_ids << product.id
          products << { product: product, price: (action == "rent" ? product.rating_price_rent : product.rating_price_sale ), intent: action, quantity: quantity, room: "" }
        end
        invoice_id = order_model&.invoices&.last&.qbo_invoice_id
        begin
            
            if invoice_id.blank?
                # create invoice here for blank orders created by admin.               
                ActiveRecord::Base.transaction do
                    order.add_products(products, email_receipt: true, user_override: current_user)
                    # cart.remove_items(product_ids) unless product_id
                    # new_lines = order_model.order_lines
                    # filtered_order_lines = new_lines.select{ |line| product_ids.include?(line.product_id) }
                    # # invoice_id = order_model&.invoices&.last&.qbo_invoice_id                    
                    # IntuitAccount.update_quickbooks_invoice(invoice_id, filtered_order_lines) if invoice_id.present?
                    customer_id = IntuitAccount.create_quickbooks_customer(current_user)
                    IntuitAccount.create_quickbooks_invoice(order_model.id, customer_id, false) if customer_id.present?
                    service = StripeInvoiceService.new(current_user, order_model) 
                    invoice = service.create_invoice(false)  if order_model.present?
                    return redirect_to(account_order_path(order_model&.id), alert: 'Order updated successfully.')
                end
            else
                # create invoice here for already existing orders with order lines.
                ActiveRecord::Base.transaction do
                    order.add_products(products, email_receipt: true, user_override: current_user)
                    # cart.remove_items(product_ids) unless product_id
                    new_lines = order_model.order_lines
                    filtered_order_lines = new_lines.select{ |line| product_ids.include?(line.product_id) }
                    added_lines = filtered_order_lines.group_by { |order_line| order_line.product_id }.values.map(&:last)
                    # invoice_id = order_model&.invoices&.last&.qbo_invoice_id
                    service = StripeInvoiceService.new(current_user, order_model)
                    invoice_id_stripe = order_model&.invoices&.last&.stripe_invoice_id
                    service.update_invoice(added_lines, invoice_id_stripe)
                    IntuitAccount.update_quickbooks_invoice(invoice_id, added_lines) if invoice_id.present?
                    return redirect_to(account_order_path(order_model&.id), alert: 'Order updated successfully.')
                end
            end
        rescue Exception => e
            # flash.alert = e.message
            return redirect_to(account_order_path(order_model&.id), alert: e.message)
        end        
        
    end    

    private
    def get_cms_fields(page, title)
        Cms.where(page: page, title: title).first
    end
end

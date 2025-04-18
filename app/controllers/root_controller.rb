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
        begin
            
            ActiveRecord::Base.transaction do
                order.add_products(products, email_receipt: true, user_override:  current_user)
                new_lines = order_model.order_lines
                filtered_order_lines = new_lines.select{ |line| product_ids.include?(line.product_id) }
                invoice_id = order_model&.invoices&.last&.qbo_invoice_id
                IntuitAccount.update_quickbooks_invoice(invoice_id, filtered_order_lines) if invoice_id.present?
                redirect_to(account_order_path(order_model&.id), notice: "added items successfully.")
            end
        rescue Exception => e
            flash.alert = e.message
        end        
        
    end    

    private
    def get_cms_fields(page, title)
        Cms.where(page: page, title: title).first
    end
end

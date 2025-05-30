module ApplicationHelper
    # include ::Sdn::Rails::Helpers::Session
    # include ::Sdn::Rails::Helpers::Formatting

    # Get the header categories
    def header_categories
        
        # binding.pry
        
        # Category.all(parent_id: nil, order: [ :display_order.asc ], :id.not => [ 2 ], active: 'active', site_id: current_user&.site_id || 26)
        Category.where(parentid: nil, active: 'active', site_id: current_user&.site_id || 26)
        .where.not(id: 2)
        .order(:order)
    end

    # Converts value to human readable with every word capitalized
    # Example: first_name -> First Name
    def humanize_and_capitalize(value)
        value.humanize.split.map(&:capitalize).join(' ')
    end

    # Returns errors for non-existent fields in field list
    def validate_required_fields(params, field_list)
        errors = []
        if missing_fields = field_list.reject { |k| params.key?(k) && params[k].strip.length > 0 } || missing_fields.any?
            missing_fields.each { |mf| errors << "Missing required field: #{humanize_and_capitalize(mf)}" }
        end
        return errors
    end

    def current_site
        return Site.find(session[:site_id] || ::SessionsController::DEFAULT_SITE_ID)
    end

    def all_sites_for_select
        Site.where.not(id: 23).map { |s| [s.name, s.id] }

        # return Site.all(:id.not => 23).map{ |s| [s.name, s.id] }
    end

    # Loads states for select dropdowns
    def states
        # binding.pry
        return @states || @states = State.order(:state).pluck(:state, :abbreviation)
    end

    # Redirects user to login modal
    def require_login
        unless user_signed_in?
            url = root_path
            return redirect_to( url + 'login')
        end
    end

    def require_roles(roles: [])
        if roles.any? && !sdn_user.type.among?(roles)
            return redirect_to(root_path + 'login')
        end
    end

    def oreder_status_notification
       queries = OrderQuery.where(recipient_id: current_user&.id, is_read: false)
       queries.map{|oq| oq.order.status}
    end  
    
    def calculate_prorate_amount(order)
        st_date = order.due_date + 31.days
        start_date = Time.parse(st_date.to_s)
        end_date = Time.parse(order.destage_date.to_s) if order.destage_date.present?
        if order.destage_date.present? && end_date > start_date
            days_between = (end_date.to_date - start_date.to_date).to_i  + 1     
            total = 0.0
            if request.url.include?("prorate")
                lines = order.order_lines.map{|a| a if a.product_id != nil }.compact
                lines.each do |ol|
                    price_per_day = ol.product.rent_per_month.to_f / 30
                    total += (price_per_day * days_between)
                end unless lines.blank?
            else
                order.products.each do |ol|
                    price_per_day = ol.product.rent_per_month.to_f / 30
                    total += (price_per_day * days_between)
                end
            end        
            
            [days_between.to_i, start_date , end_date , total]
        else
            [0]
        end            
    end

    def cart_items_count(cart)
        quantity = 0
        cart.items.each do |item|
          quantity += item[:quantity].to_i
        end if cart.present? && cart.items.count > 0
        quantity
    end
    def product_status(id, line_id) 
        ProductPiece.where(product_id: id, order_line_id: line_id).first&.status
    end    
    def get_status(id)
      statuses = {}   
      order = Order.first(id: id)
      product_pieces = JSON.parse(order&.order_log&.product_pieces)
      product_pieces.to_h if product_pieces.present?
      product_pieces.each do |key, value|
         status = ProductPiece.where(id: value, product_id: key).first&.status
         statuses[key] =  status == "Available" ? "Received" : status
      end  
      statuses
    end
    def reviewed?(order_id, product_id)
      rating = Rating.where(order_id: order_id, product_id: product_id)&.first
      rating.present? ? true : false
    end    
end

require 'uri'

class ProductsController < ApplicationController

    # const_def :BEDROOM_CATEGORY_ID, 78
    # const_def :SOFA_CATEGORY_ID, 17

    BEDROOM_CATEGORY_ID = 78
    SOFA_CATEGORY_ID = 17

    def index    
        if params[:_x]
            unset = params[:_x].split(',')
            new_filters = session[:filters]
            unset.each do |f|
                new_filters&.delete(f)
            end
            new_filters = nil unless new_filters&.any?
            session[:filters] = new_filters
            params.delete(:_x)
        end
  
        @all_colors = Product.get_colors
        @all_materials = Product.get_materials
        @all_sizes = Product.get_sizes
        category_id = params[:category] ? params[:category].to_i : nil
        @current_category = Category.select(:id, :name).find_by(id: category_id)
        # Category.first(fields: [ :id, :name ], id: category_id)
        return redirect_back(fallback_location: plp_path, alert: 'Invalid category.') if category_id && !@current_category



        # Pagination
        page = params[:page]
        if page == 'all'
            @per_page = 42069
            limit = @per_page
            offset = 0
        else
            @page = page&.to_i || 1
            @per_page = 9
            limit = @per_page
            offset = @per_page * (@page - 1)
        end

        @persistent_filters = [ :intent, :favorites, :owned ]
        #         binding.pry

        # params.select{ |k| k.to_sym.include?(@persistent_filters) }.each do |filter, val|
        #     session[:filters] ||= {}
        #     session[:filters][filter.to_sym] = val
        # end

        params.each do |k, val|
            if @persistent_filters.include?(k.to_sym)
              session[:filters] ||= {}
              session[:filters][k.to_sym] = val
            end
          end

        # Get values from params or session
        intent = params[:intent] || session[:filters]&.fetch(:intent, nil)
        params.merge!(intent: intent) if intent
        if user_signed_in?
            favorites = params[:favorites] == 'y' || session[:filters]&.fetch(:favorites, 'n') == 'y'
            params.merge!(favorites: 'y') if favorites
            owned = params[:owned] == 'y' || session[:filters]&.fetch(:owned, 'n') == 'y'
            params.merge!(owned: 'y') if owned
        end

        # Forces closeout filter for Kirkland site for warehouse sale
        params[:closeout] = 'y' if current_site&.id == 23
        unless user_signed_in?
            site_id = Site.where(site: 'RE|Furnish')&.pluck(:id)
        else    
            site_id = Site.where(id: current_user&.location_rights&.split(','))&.pluck(:id)
        end    
        
        filters = {
            site_id:           params[:site] || site_id,
            category_id:       category_id,
            premium:           params[:premium],
            closeout:          params[:closeout],
            discount_rental:   params[:discount],
            on_sale:           params[:sale],
            color_id:          params[:color],
            material_id:       params[:material],
            size_id:           params[:size],
            bed_size_id:       params[:bed],
            sofa_size_id:      params[:sofa],
            intent:            "rent",
            favorites_user_id: (user_signed_in? && params[:favorites] == 'y') ? current_user&.id : nil,
            owner_user_id:     (user_signed_in? && params[:owned] == 'y') ? current_user&.id : nil,
            price_min:         params[:pmin],
            price_max:         params[:pmax],
            width_min:         params[:wmin],
            width_max:         params[:wmax],
            height_min:        params[:hmin],
            height_max:        params[:hmax],
            depth_min:         params[:dmin],
            depth_max:         params[:dmax],
            sort:              params[:sort],
            search_query:      params[:search],
            hide_reserved:     true,
            hide_no_image:     false,
            hide_red_tag_bin:  true,
            hide_hidden_bin:   true,
            hide_ps_bins:      true,
        }


        filters = { product_ids: @inhome_product_ids, show_on_frontend_only: false } if @inhome_product_ids
        # not_available_products = Product.products_in_open_orders
# binding.pry
        all_product_ids = Barcode.available_product_ids(**filters) 
        @product_count = all_product_ids.size
        product_ids = all_product_ids[offset, limit]
        product_ids.uniq! if product_ids.present?

        if product_ids.blank? && is_number?(params[:search]&.split('-')&.last) 
            product_ids << ProductPiece.first(product_epc_id: params[:search]&.split('-')&.last)&.product_id
        end

        # Gets product models and ancillary data/assets
        product_images = Product.get_main_images(product_ids)
        flagged_products = Product.get_flags(product_ids)
        user_favorites = user_signed_in? ? UserWishlist.where(user: current_user).pluck(:product_id) : []
        
             
        # products = Product.all(fields: [ :id, :product, :rent_per_month, :sale_price, :for_sale, :for_rent ], id: product_ids)
        products = Product
           .where(id: product_ids)
        #    .select(:id, :product, :rent_per_month, :sale_price, :for_sale, :for_rent)

        @products = products.map do |product|
            OpenStruct.new(
                id:               product.id,
                rating:           product.quality_rating,
                quantity:         product.quantity,
                name:             product.name,
                site:             product.site_id,
                color:            product&.site&.color,
                pieces_count:     product.product_pieces.count,
                product_pieces_order_line:  product.product_pieces.map{|pp| pp.order_line_id},
                premium?:         flagged_products.find{ |p| p.product_id == product.id }&.premium?,
                closeout?:        flagged_products.find{ |p| p.product_id == product.id }&.closeout?,
                discount_rental?: flagged_products.find{ |p| p.product_id == product.id }&.discount_rental?,
                sales_item?:      flagged_products.find{ |p| p.product_id == product.id }&.sales_item?,
                favorite?:        user_favorites.include?(product.id),
                owned?:           product.customer_id == current_user&.id,
                main_image_url:   product_images.find{ |p| p.product_id == product.id }&.image_url,
                rent_per_month:   product.rating_price_rent,
                width:            product.width,
                height:           product.height,
                depth:            product.depth,
                sale_price:       product.rating_price_sale,
                for_rent?:        product.for_rent,
                for_sale?:        product.for_sale,
            )
        end


        @products.sort_by!{ |e| all_product_ids.index e.id } # match sorting of original ID's... #map doesn't maintain order

        if request.xhr?
            @no_filters = true
            return render(layout: 'blank')
        else
            session[:product_ids] = []   # remove duplicates on production only.
        end

        # Filter data
        # TODO: Re-add category counts within the scope
        # TODO: Refactor/abstract this category logic
        # binding.pry
        scoped_options = Product.product_options(all_product_ids)
        @colors = params[:color].present? ? Product.get_active_colors(params[:color]) : Product.get_colors
        @materials = params[:material].present? ? Product.get_active_materials(params[:material]) : Product.get_materials
        @sizes = params[:size].present? ? Product.get_active_sizes(params[:size]) : Product.get_sizes
        
        @sites = Site.where(id: current_user&.location_rights&.split(',')&.map(&:to_i))
        # @sites = Site.all

        if [@current_category&.id, @current_category&.parent_id].include?(BEDROOM_CATEGORY_ID) 
            @bed_sizes = scoped_options.pluck('bed_size_id', 'bed_size').select{ |e| e[0] && e[1] }.map{ |e| OpenStruct.new(id: e[0], label: e[1]) }.uniq
        end
        if [@current_category&.id, @current_category&.parent_id].include?(SOFA_CATEGORY_ID)
            @sofa_sizes = scoped_options.pluck('sofa_size_id', 'sofa_size').select{ |e| e[0] && e[1] }.map{ |e| OpenStruct.new(id: e[0], label: e[1]) }.uniq.sort_by{ |e| e.id }
        end
        @categories = scoped_options.pluck(:parent_category_id, :parent_category_name, :category_id, :category_name, :child_category_id, :child_category_name).select{ |e| e[2] && e[3] }.group_by{ |e| e[0] }

        @categories = @categories.map do |categories_by_parent|
            OpenStruct.new(
                id: categories_by_parent[0],
                label: categories_by_parent[1].first[1],
                children: categories_by_parent[1].map{ |e| OpenStruct.new( id: e[2], label: e[3]) }.uniq.sort{ |a,b| a.label <=> b.label },
            )
        end
        # @categories.sort!{ |a,b| a.label <=> b.label }
        @price_minmax = Barcode.price_minmax_range(filters: filters)
        @dimensions_minmax = Barcode.dimensions_minmax_range(filters: filters)

        valid_filters = [ :category, :color, :search, :intent, :site, :size, :material, :sort, :premium, :closeout, :discount, :sale, :favorites, :owned, :pmin, :pmax, :wmin, :wmax, :dmin, :dmax, :hmin, :hmax, :bed, :sofa ]
        # binding.pry
        @active_filters = params.to_unsafe_hash.symbolize_keys.select{ |k,_| valid_filters.include?(k) }.map do |key, value|
            
            case key
            when :category
                category = @current_category
                crumbs = [ category.name ]
                while category.parent
                    category = category.parent
                    crumbs << category.name if category.parent
                end

                { key: 'category',  key_label: nil, value: value, value_label: crumbs.reverse.join(' &raquo; ').html_safe || value, }
            when :intent
                { key: 'intent',    key_label: 'Availability', value: value, value_label: value.capitalize, }
            when :color
                { key: 'color',     key_label: 'Color', value: value, value_label: Product.get_active_colors(params[:color]).map{|c| c.label}, }
            when :site
                { key: 'site',      key_label: 'Site', value: value, value_label: Site.get(value.to_i)&.site, }
            when :material
                { key: 'material',  key_label: 'Material', value: value, value_label: Product.get_active_materials(params[:material]).map{|c| c.label}, }
            when :size
                { key: 'size',      key_label: 'Size', value: value, value_label: Product.get_active_sizes(params[:size]).map{|c| c.label}, }
            when :premium
                { key: 'premium',   key_label: nil, value_label: 'Premium', }
            when :closeout
                { key: 'closeout',  key_label: nil, value_label: 'Closeout', }
            when :discount
                { key: 'discount',  key_label: nil, value_label: 'Rental Discount', }
            when :sale
                { key: 'sale',      key_label: nil, value_label: 'Sale', }
            when :discount_rental
                { key: 'material',  key_label: 'Material', value: value, value_label: Option.get(value.to_i)&.label, }
            when :favorites
                { key: 'favorites', key_label: nil, value_label: 'Favorites', }
            when :owned
                { key: 'owned',     key_label: nil, value_label: 'My Inventory', }
            when :sort
                { key: 'sort',      key_label: 'Sort', value: value, value_label: value.to_s, }
            when :pmin
                { key: 'pmin',      key_label: 'Price Min', value_label: "$#{value}", }
            when :pmax
                { key: 'pmax',      key_label: 'Price Max', value_label: "$#{value}", }
            when :wmin
                { key: 'wmin',      key_label: 'Width Min', value_label: "#{value}", }
            when :wmax
                { key: 'wmax',      key_label: 'Width Max', value_label: "#{value}", }
            when :dmin
                { key: 'dmin',      key_label: 'Depth Min', value_label: "#{value}", }
            when :dmax
                { key: 'dmax',      key_label: 'Depth Max', value_label: "#{value}", }
            when :hmin
                { key: 'hmin',      key_label: 'Height Min', value_label: "#{value}", }
            when :hmax
                { key: 'hmax',      key_label: 'Height Max', value_label: "#{value}", }
            when :bed
                { key: 'bed',       key_label: 'Bed Size', value_label: Option.get(value.to_i)&.label, }
            when :sofa
                { key: 'sofa',      key_label: 'Sofa Size', value_label: Option.get(value.to_i)&.label&.html_safe, }
            else
                { key: key, key_label: key.capitalize, value: value, value_label: value.capitalize, }
            end
        end
        # Consolidate range filters
        range_filters = [[:pmin, :pmax, 'Price'], [:hmin, :hmax, 'Height'], [:wmin, :wmax, 'Width'], [:dmin, :dmax, 'Depth']]
        filter_keys = @active_filters.pluck(:key).map{ |k| k.to_sym }
        range_filters.each do |pair|
            min_key = pair[0]
            max_key = pair[1]
            label = pair[2]
            if filter_keys.include?(min_key) && filter_keys.include?(max_key)
                min = @active_filters.find{ |f| f[:key].to_sym == min_key }
                max = @active_filters.find{ |f| f[:key].to_sym == max_key }
                @active_filters << { key: [min_key, max_key], key_label: label, value_label: "#{min[:value_label]} - #{max[:value_label]}", }
                # @active_filters.delete_if { |f| f[:key].to_s.to_sym.include?(min_key, max_key) }
                @active_filters.delete_if { |f| [min_key, max_key].include?(f[:key].to_s.to_sym) }
            end
        end

        @user_has_inventory = Barcode.available_product_ids_count(filters.merge({ owner_user_id: current_user.id })) > 0 if user_signed_in?

        render 'index'
    end

    def inhome
        order_id = params[:id].to_i

        order = Order.first(id: order_id, status: 'Renting', type: 'Rental')
        orders = order.sibling_rental_orders(include_source: true)

        @no_filters = true
        @in_home = true

        @address = order.address

        @inhome_product_ids = []
        orders.each do |o|
            @inhome_product_ids += o.order_lines.product_lines.map{ |l| l.product_id }
        end

        return index
    end

    # Search bar auto suggestions
    # TODO: Eventually this might need to be abstracted as search expands to more than products
    def search_suggest
        q = params[:q].to_s
        return unless q.length > 2

        filters = {
            search_query: q,
            site_id: [current_site&.id],
            hide_reserved: true,
            hide_no_image: true,
            limit: 10,
        }

        # Search operators
        #
        # Examples:
        # Find all products matching ID(s), ignoring site_id/reserved status/missing image:
        #   "id: 1234, 3242, 55656"
        op_string = q.split(':')
        if op_string.size > 1
            op_key = op_string.shift.downcase
            op_val = op_string.join('').downcase

            case op_key
            when 'id'
                filters = {
                    product_ids: op_val.split(',').map(&:to_i),
                    hide_reserved: false,
                    hide_no_image: false,
                }
                filters[:limit] = filters[:product_ids].size
            end
        end

        product_ids = Barcode.available_product_ids(**filters)

        data = Product.all(
            fields: [ :id, :product ],
            id: product_ids,
            order: :product.asc
        ).pluck(:id, :product).map{ |id, name| {
            id: id,
            name: name,
        }}

        render json: data
    end

    def rooms
        render
    end

    def category
        # TODO: REPLACE CODE
        if params.include?('intent') && ['buy','rent'].any? { |e| params[:intent].include? e }
            for_sale = params[:intent] == 'buy'
            for_rent = params[:intent] == 'rent'
        else
            for_sale = true
            for_rent = true
        end

        # Get the products
        # TODO: Add/invoke pagination helper (https://www.rubydoc.info/gems/dm-pager/1.1.0/DataMapper/Pagination)
        @products = Product.all(
            active: 'Active',
            for_sale: for_sale,
            for_rent: for_rent,
            limit: 10
        ).not_reserved.all_available

        $LOG.debug (@current_user&.email || 'guest@guest.log')  + ' -> PLP -> ' + params.except(:controller, :action).to_s

        render
    end

    # Product detail page (PDP)
    def show
        product_id = params[:id].to_i
        @product = Product.active.where(id: product_id)&.first
        return redirect_to(plp_path, alert: 'Product is unavailable.') unless @product
        @rooms = Room.active_rooms_ordered_by_position(current_user&.id).map{ |r| OpenStruct.new(id: r.id, name: r.name) }
        @is_available = Barcode.available_product_id(product_id, hide_reserved: true, hide_red_tag_bin: true, hide_hidden_bin: true, hide_ps_bins: true).present?

        # Orders to add to
        @orders_to_add_to = []
        if user_signed_in? && @product.is_rentable?
            otat = current_user.orders.open.rentals.for_site(@product.site.id)
            otat = otat.select{ |o| !o.frozen? }  unless session[:god] === true
            @orders_to_add_to = otat.map do |order|
                OpenStruct.new( id: order.id, project: order.project_name.presence, address: order.address&.address1 )
            end
        end

        # Related products
        related_product_ids = Barcode.available_product_ids(
            site_id: [current_site&.id],
            category_id: @product&.category&.id,
            limit: 8,
            exclude_product_ids: product_id,
            intent: 'rent',

        )
        related_product_images = Product.get_main_images(related_product_ids)
        @related_products = Product.where(id: related_product_ids).map do |product|
            OpenStruct.new(
                id:             product.id,
                name:           product.name,
                main_image_url: related_product_images.find{ |e| e.product_id == product.id }&.image_url,
                rent_per_month: product.rating_price_rent,
                sale_price:     product.rating_price_sale,
                for_rent?:      product.for_rent,
                for_sale?:      product.for_sale,
            )
        end

        return render(json: { html: render_to_string(partial: 'item_detail', locals: { product: @product, orders_to_add_to: @orders_to_add_to, is_available: @is_available }, layout: false), }) if request.xhr?
        return render
    end

    def barcode
        @pp = ProductPiece.first(order_line_id: params[:line])
        @product = @pp.product if @pp.present?        
    end

    def autocomplete
        term = params[:term]
        products = Product.all(site_id: current_user&.site_id, :product.like => "%#{term}%", :limit => 10, :fields => [:id, :product, :rent_per_month, :quantity])
        render json: products
    end  

    def autocomplete_bins
        term = params[:query]
        bins = Bin.all(
            :site_id => current_user&.site_id,
            :conditions => ["CAST(id AS CHAR) LIKE ?", "%#{term}%"],
            :limit => 10
          )        
        render json: bins.map { |bin| bin.bin }
    end  
      

    private

    def is_number?(str)
        !!str.match(/\A[-+]?[0-9]*\.?[0-9]+\z/)
    end

end

class Barcode < ApplicationRecord
    # Belongs to associations (foreign key references the associated model)
    belongs_to :product_piece
    belongs_to :product
    belongs_to :site
    belongs_to :bin, optional: true  # Since bin_id can be nil
  
    # Has many association (as there can be multiple product_piece_locations for a barcode)
    has_many :product_piece_locations, foreign_key: :product_piece_id
    
    # Validations, if any (optional)
    validates :product_piece_id, presence: true
    validates :product_id, presence: true
    validates :site_id, presence: true
    # include DataMapper::Resource

    # property :product_piece_id, Integer, index: true, key: true
    # belongs_to :product_piece
    # has n, :product_piece_locations, model: 'ProductPieceLocation', parent_key: [ :product_piece_id ], child_key: [ :product_piece_id ]

    # property :product_id, Integer, index: true
    # belongs_to :product

    # property :site_id, Integer, index: true, lazy: false
    # belongs_to :site

    # property :bin_id, Integer, index: true, allow_nil: true
    # belongs_to :bin

    # property :show_on_frontend, Boolean, default: false

    # property :last_order_id, Integer, allow_nil: true

    # timestamps :at

    # Gets the last PPL scan (PPL) status
    def last_scan
        ProductPieceLocation.first(product_piece_id: product_piece_id, log_status: 'Posted', log_type: 'OnOrder', table_name: 'orders', void: 'no', order: [ :id.desc ])
    end

    # Scope for getting specific last scan (PPL) log_type
    def self.last_scan_type_not(type: nil)
        # all( Barcode.product_piece_locations. )
    end

    # Gets single, available product ID
    def self.available_product_id(product_id, site_id:nil, intent:nil, hide_reserved: false, hide_red_tag_bin: false, hide_hidden_bin: false, hide_ps_bins: false)
        return self.available_product_ids(product_ids: product_id, site_id: site_id, limit: 1, hide_reserved: hide_reserved, hide_red_tag_bin: hide_red_tag_bin, hide_hidden_bin: hide_hidden_bin, hide_ps_bins: hide_ps_bins).first
    end

    def self.available_product_ids_count(filters)
        return self.available_product_ids(**filters.merge({ count_only: true })).first.to_i
    end

    # Gets the min/max prices of supplied filters OR product ids and intent
    def self.price_minmax_range(filters: nil, pids: [], intent: nil, round: true)
        if pids&.any?
            ids = pids
        else
            ids = self.available_product_ids(**filters.except(:price_min, :price_max))
            intent = filters[:intent]
        end

        price_field = intent == 'buy' ? 'sale_price' : 'rent_per_month'
        # prices = Product.all(fields: [ price_field.to_sym ], :id => ids).pluck(price_field.to_sym)
        prices = Product
          .where(id: ids)
          .pluck(price_field.to_sym)


        return { min: round ? prices.min&.floor : prices.min, max: round ? prices.max&.ceil : prices.max }
    end

    def self.dimensions_minmax_range(filters: nil, pids: [], intent: nil, round: true)
        if pids&.any?
            ids = pids
        else
            ids = self.available_product_ids(**filters.except(:width_min, :width_max, :height_min, :height_max, :depth_min, :depth_max))
            intent = filters[:intent]
        end

        dims = Product.where(id: ids)
        width = dims.pluck(:width)
        depth = dims.pluck(:depth)
        height = dims.pluck(:height)
        return {
            wmin: round ? width.min&.floor : width.min,
            wmax: round ? width.max&.floor : width.max,
            dmin: round ? depth.min&.floor : depth.min,
            dmax: round ? depth.max&.floor : depth.max,
            hmin: round ? height.min&.floor : height.min,
            hmax: round ? height.max&.floor : height.max,
        }
    end

    def self.available_product_ids(**o)
        # Ranked search query results
        #
        # This is kind of a hacky way to do this, basically performing three queries:
        #
        #   1) Find category name AND product name match
        #   2) Find category name match
        #   3) Find product name match
        #
        # The result from all three queries are merged together in that order (implemented
        # in reverse) and de-duplicated.
        if o[:search_query]
            o[:sort] = false

            ranked_ids = []
            ranked_ids += Barcode.query_available_product_ids(**o)

            query = o.extract!(:search_query).fetch(:search_query)

            o[:search_category] = query
            ranked_ids += Barcode.query_available_product_ids(**o)

            o[:search_product] = query
            ranked_ids += Barcode.query_available_product_ids(**o)

            return ranked_ids.uniq.reverse
        end

        return Barcode.query_available_product_ids(**o)
    end

    # Gets product ID's constrained by supplied options
    #
    # This method serves as the "master" query for getting available product ID's that
    # can be added to an order.
    #
    # Available options:
    #  site_id                     Site/location ID
    #  category_id                 A single category ID to filter by (Also grabs all child ID's)
    #  excluded_category_ids       Array of category ID's to exclude products from
    #  premium                     'y' or 'n' to filter by premium products or not
    #  closeout                    'y' or 'n' to filter by closeout products or not
    #  discount_rental             'y' or 'n' to filter by discount rental products or not
    #  on_sale                     'y' or 'n' to filter by on sale items or not
    #  intent                      'buy' or 'rent'
    #  color                       ID of `yuxi_options` tag = 'COLOR' - currently only one supported
    #  material                    ID of `yuxi_options` tag = 'MATERIAL' - currently only one supported
    #  bed_size_id                 ID of `yuxi_options` tag = 'BED_SIZE'
    #  sofa_size_id                ID of `yuxi_options` tag = 'SOFA_SIZE'
    #  price_min                   Min price for selected intent (default is rental price)
    #  price_max                   Max price for selected intent (default is rental price)
    #  width_min                   Min width
    #  width_max                   Max width
    #  height_min                  Min height
    #  height_max                  Max height
    #  depth_min                   Min depth
    #  depth_max                   Max depth
    #  search_query                Product name or ID search (at the moment)
    #  search_product              Product name search
    #  search_category             Category name search (if search_product and search_category, AND added)
    #  product_ids                 One or more product ID's
    #  exclude_product_ids         One or more product ID's to explicitly exclude
    #  favorites_user_id           Favorites for supplied user ID
    #  owner_user_id               Products belonging to supplied user ID
    #  sort                        'plth' or 'phtl' (price high to low); false disables; defaults to newest products
    #  limit                       Limit of returned results (default is MySQL max)
    #  offset                      Offset of returned results
    #  hide_reserved               Boolean of whether to hide products reserved in a user's cart
    #  hide_no_image               Boolean of whether to hide products with no image
    #  hide_inactive               Boolean of whether to hide products without Active status
    #  hide_red_tag_bin            Boolean of whether to hide products stored in a red tag bin; defaults false
    #  show_on_frontend_only       Boolean of whether to include show_on_frontend = true logic
    #  bin_show_on_frontend_only   Boolean of whether to include show_on_frontend = true logic for bins
    #  hide_private                Boolean of whether to hide products where for_sale and for_rent = false
    #  hide_hidden_bin             Boolean of whether to hide products stored in a hidden bin
    #  hide_ps_bins                Boolean of whether to hide products stored in bins starting with "ps"
    #  count_only                  Returns the count of the product ID's and not the product ID's
    #  hide_mixed_site_ids         Boolean of whether to hide products with barcodes in multiple sites
    #  hide_mixed_sofe             Boolean of whether to hide products with mixed show_on_frontend
    def self.query_available_product_ids(**o)
        # Default values
        o[:site_id]                   = o[:site_id] if o[:site_id]
        o[:category_id]               = o[:category_id].to_i
        o[:product_ids]               = Array(o[:product_ids]).map(&:to_i) if o[:product_ids]
        o[:exclude_product_ids]       = Array(o[:exclude_product_ids]).map(&:to_i) if o[:exclude_product_ids]
        o[:exclude_ids_category]      = o.fetch(:exclude_ids_category, true)
        o[:favorites_user_id]         = o[:favorites_user_id].to_i if o[:favorites_user_id]
        o[:owner_user_id]             = o[:owner_user_id].to_i if o[:owner_user_id]
        o[:limit]                     = 18446744073709551610 if o[:limit].to_i <= 0
        o[:offset]                    = 0 if o[:offset].to_i <= 0
        o[:hide_reserved]             = o.fetch(:hide_reserved,          false)
        o[:hide_inactive]             = o.fetch(:hide_inactive,          true)
        o[:count_only]                = o.fetch(:count_only,             false)
        o[:hide_red_tag_bin]          = o.fetch(:hide_red_tag_bin,       false)
        o[:show_on_frontend_only]     = o.fetch(:show_on_frontend_only,  true)
        o[:bin_show_on_frontend_only] = o.fetch(:bin_show_on_frontend_only, true)
        o[:hide_private]              = o.fetch(:hide_private,           true)
        o[:hide_hidden_bin]           = o.fetch(:hide_hidden_bin,        false)
        o[:hide_ps_bins]              = o.fetch(:hide_ps_bins,           false)
        o[:hide_mixed_site_ids]       = o.fetch(:hide_mixed_site_ids,    true)
        o[:hide_mixed_sofe]           = o.fetch(:hide_mixed_sofe,        true)

        price_field = o[:intent] == 'buy' ? 'sale_price' : 'rent_per_month'

        # j = "INNER JOIN `products` ON `barcodes`.`product_id` = `products`.`id` "
        j = ""
        w = "TRUE "
        group = "`products`.`id` "
        h = "TRUE "

        p = []

        if o[:count_only]
            s = "COUNT(DISTINCT `products`.`id`) "
            group = "NULL"
        else
            s = "`products`.`id` AS product_id"
        end

        # if o[:show_on_frontend_only]
        #     h += "AND MIN(`barcodes`.`show_on_frontend`) = 1 "
        # end

        if (o.keys & [ :category_id, :excluded_category_ids, :exclude_ids_category, :premium, :closeout, :discount_rental, :on_sale, :color_id, :material_id, :size_id, :search_product, :search_category, :bed_size_id, :sofa_size_id, ]).any?
            j += "INNER JOIN `yuxi_products` ON `products`.`id` = `yuxi_products`.`product_id` "

            if o[:exclude_ids_category]
                o[:excluded_category_ids] = Array(o[:excluded_category_ids])
                o[:excluded_category_ids] += [ 2, 203, 204 ]
            end

            if o[:site_id].present?
                site_ids = o[:site_id].is_a?(Array) ? o[:site_id] : [o[:site_id]]
                w += "AND `products`.`site_id` IN (#{site_ids.join(',')}) "
            end

            if Array(o[:excluded_category_ids]).any?
                w += "AND `yuxi_products`.`category_id` NOT IN (%s) " % [ (Array(o[:excluded_category_ids]).join(',') rescue 0) ]
            end

            if o[:category_id] > 0
                category_ids = Category.find(o[:category_id])&.id_tree || [ 99999 ] # causes no results if category doesn't exist
                w += "AND `yuxi_products`.`category_id` IN (%s) " % [ category_ids.join(',') ]
            end

            yp_bool_sql = ->(db_col, key) do
                yn = o.fetch(key, nil)
                # binding.pry
                w += "AND `yuxi_products`.`%s` = %s " % [ db_col, yn == 'y' ? 'TRUE' : 'FALSE' ] if yn.present? && yn.include?('y', 'n')
            end
            yp_bool_sql.call('is_premium', :premium)
            yp_bool_sql.call('closeout', :closeout)
            yp_bool_sql.call('discount_rental', :discount_rental)
            yp_bool_sql.call('sales_item', :on_sale)

            if o[:color_id]
                w += "AND `yuxi_products`.`color_id` IN (#{o[:color_id]}) "
            end

            if o[:material_id]
                w += "AND `yuxi_products`.`material_id` = #{o[:material_id].to_i} "
            end

            if o[:size_id]
                w += "AND `yuxi_products`.`size_id` = #{o[:size_id].to_i} "
            end

            if o[:bed_size_id]
                w += "AND `yuxi_products`.`size_id` = #{o[:bed_size_id].to_i} "
            end

            if o[:sofa_size_id]
                w += "AND `yuxi_products`.`size_id` = #{o[:sofa_size_id].to_i} "
            end
        end

        if o[:hide_private]
            # binding.pry 
            if o[:intent].present? && o[:intent].include?('buy') || o[:intent].present? && o[:intent].include?('rent')
                w += "AND `products`.`for_%s` = TRUE " % [ o[:intent] == 'buy' ? 'sale' : 'rent' ]
            else
                w += "AND (`products`.`for_sale` = TRUE OR `products`.`for_rent` = TRUE) "
            end
        end

        if o[:favorites_user_id]
            j += "INNER JOIN `user_wishlist` ON `products`.`id` = `user_wishlist`.`product_id` AND `user_wishlist`.`user_id` = ? "
            p << o[:favorites_user_id]
        end

        if o[:owner_user_id]
            w += "AND `products`.`customer_id` = ? "
            p << o[:owner_user_id]
        end
# binding.pry
        if o[:sort].present? && o[:sort].include?('plth') || o[:sort].present? && o[:sort].include?('phtl')
            # binding.pry
            order = "`products`.`%s` %s, `products`.`product` ASC " % [ price_field, o[:sort] == 'plth' ? 'ASC' : 'DESC' ]
               
        elsif o[:sort] == 'rrp'
            j += "INNER JOIN `order_lines` ON `products`.`id` = `order_lines`.`product_id` "
            j += "INNER JOIN `orders` ON `order_lines`.`order_id` = `orders`.`id` "
            w += "AND `orders`.`status` = 'Destage' "
            order = "`orders`.`id` DESC "
        
        
        elsif o[:sort] == false
            order = 'NULL'
        else
            order = "`products`.`created` DESC "
        end


        if o[:sort].present? && o[:sort].include?('qlth') || o[:sort].present? && o[:sort].include?('qhtl')
            if o[:sort] == 'qlth'
                order = "CASE WHEN `products`.`quantity` != 0 THEN 0 ELSE 1 END ASC, `products`.`quantity` ASC"
            elsif o[:sort] == 'qhtl'
                order = "`products`.`quantity` DESC"
            else
                order = 'NULL'    
            end
        end


        # if o[:product_ids]
        #     w += "AND `barcodes`.`product_id` IN (%s) " % [ o[:product_ids].join(',') ]
        # end

        # if o[:exclude_product_ids]
        #     w += "AND `barcodes`.`product_id` NOT IN (%s) " % [ o[:exclude_product_ids].join(',') ]
        # end

        # Show/hide items in a user's cart
        if o[:hide_reserved]
            w += "AND NOT EXISTS (SELECT `id` FROM `product_reservations` WHERE `product_reservations`.`product_id` = `products`.`id`) "
        end

        if o[:hide_inactive]
            w += "AND `products`.`active` = 'Active' "
        end

        if o[:hide_no_image]
            w += "AND EXISTS (SELECT `id` FROM `product_images` WHERE `product_images`.`product_id` = `products`.`id` AND `product_images`.`image_order` = 1) "
        end

        # if o[:hide_red_tag_bin] || o[:hide_hidden_bin] || o[:hide_ps_bins] || o[:bin_show_on_frontend_only]
        #     j += "LEFT JOIN `site_bins` ON `barcodes`.`bin_id` = `site_bins`.`id` "
        #     h += "AND MIN(`site_bins`.`show_on_frontend`) = 1 " if o[:bin_show_on_frontend_only]
        # end

        # if o[:hide_mixed_site_ids]
        #     h += "AND STD(`barcodes`.`site_id`) = 0 "
        # end

        # if o[:hide_mixed_sofe] # sofe = show_on_frontend
        #     h += "AND STD(`barcodes`.`show_on_frontend`) = 0 "
        # end

        if o[:price_min]
            w += "AND `products`.`%s` >= %s " % [ price_field, o[:price_min].to_f ]
        end

        if o[:price_max]
            w += "AND `products`.`%s` <= %s " % [ price_field, o[:price_max].to_f ]
        end

        w += "AND `products`.`width` >= #{o[:width_min].to_i} " if o[:width_min]
        w += "AND `products`.`width` <= #{o[:width_max].to_i} " if o[:width_max]
        w += "AND `products`.`depth` >= #{o[:depth_min].to_i} " if o[:depth_min]
        w += "AND `products`.`depth` <= #{o[:depth_max].to_i} " if o[:depth_max]
        w += "AND `products`.`height` >= #{o[:height_min].to_i} " if o[:height_min]
        w += "AND `products`.`height` <= #{o[:height_max].to_i} " if o[:height_max]
          
        if o[:search_query]
            w += "AND (`products`.`product` LIKE ? ) "
            p << "%#{o[:search_query]}%"
            # p << "#{o[:search_query].to_i}"
        end

        # NOTE: This will only search category names with a single nesting depth.
        if o[:search_product] || o[:search_category]
            j += "LEFT JOIN `yuxi_categories` AS `yc_child` ON `yuxi_products`.`category_id` = `yc_child`.`id` "
            j += "LEFT JOIN `yuxi_categories` AS `yc_parent` ON `yc_child`.`parentid` = `yc_parent`.`id` "

            if o[:search_category] && o[:search_product]
                w += "AND ((LOWER(`yc_parent`.`name`) LIKE ? OR LOWER(`yc_child`.`name`) LIKE ?) AND LOWER(`products`.`product`) LIKE ?) "
                p += ["%#{o[:search_category]}%"] * 2
                p << "%#{o[:search_product]}%"
            elsif o[:search_category]
                w += "AND (LOWER(`yc_parent`.`name`) LIKE ? OR LOWER(`yc_child`.`name`) LIKE ?) "
                p += ["%#{o[:search_category]}%"] * 2
            elsif o[:search_product]
                w += "AND LOWER(`products`.`product`) LIKE ? "
                p << "%#{o[:search_product]}%"
            end
        end
        query = "SELECT #{s} FROM `products` #{j} WHERE (#{w}) GROUP BY #{group} HAVING #{h} ORDER BY #{order} LIMIT #{o[:offset]}, #{o[:limit]}"
        # binding.pry
        # return repository(:default).adapter.select(query, *p) 
        
        unless p.empty?
            return [2]
            # binding.pry
            # puts p.inspect+"SSSSSSSSSSSSSSSSSSSSSSSSS"
        end
        result = ActiveRecord::Base.connection.execute(query)
        array_ids = result.map { |row| row[0]  }
        # binding.pry
        return array_ids

        # return $DB.select(query)  # return like [121,34234,343,342,32432,465,5467]
    end

end

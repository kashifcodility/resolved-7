# TODO: Consolidate scoping logic with attribute checking logic
class Product
    include DataMapper::Resource

    property :id, Serial

    property :type, String, length: 20, default: 'Rental&Resale'

    property :active, StringEnum['Active','Damaged','Does Not Exist','Donated','Inactive','Missing','OBNH','On Hold','Rebarcoded','Returned to Owner','Shrink','Sold','Transfer'], default: "Active"
    def active?()  active == 'Active'  end
    def self.active() all(active: 'Active') end    

    property :upc, String, length: 50, allow_nil: true
    property :serial, String, length: 30, allow_nil: true

    property :product, String, length: 50, index: true

    # Some of our past product data entry has some bullshit MS Word encoding. This fixes that.
    # We should ultimately do a cleanup of the database data, but this is the fix for now.
    def name
        return product
        # return product.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "").force_encoding('UTF-8')
    end

    property :quantity, Integer, default: 1

    property :for_sale, Boolean, default: true
    def self.buyable() all(for_sale: true) end
    property :for_rent, Boolean, default: true
    def self.rentable() all(for_rent: true) end

    property :smoking, Boolean, default: false
    property :pets, Boolean, default: false
    property :owner_occupied, Boolean, default: false
    property :children, Boolean, default: false
    property :reserved, Boolean, default: false
    property :box, Boolean, default: false

    property :stored, String, length: 30, default: "Warehouse"
    property :status, String, length: 30, default: "Available"

    property :storage_price, Decimal, precision: 12, scale: 2, default: 0.25
    property :catalog_price, Decimal, precision: 10, scale: 2, allow_nil: true
    property :sdn_cost, Decimal, precision: 10, scale: 2
    property :income, Decimal, precision: 12, scale: 2, allow_nil: true

    property :description,      String, length: 500, allow_nil: true
    # Some of our past product data entry has some bullshit MS Word encoding. This fixes that.
    # We should ultimately do a cleanup of the database data, but this is the fix for now.
    def about
        return description
        # self.description.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "").force_encoding('UTF-8')
    end

    property :long_description, String, length: 500
    property :product_restrictions, Text

    property :available, Date

    # TODO: WTF does this go to?
    property :main_image_id, Integer

    has 0..n, :product_images

    # Orders the images by order and returns their associated Image model
    # TODO: This could probably be done with has n through association
    def images()
        self.product_images(order: [ :image_order ]).map { |pivot| pivot.image }
    end

    def main_image()
        if self.main_image_id && self.main_image_id > 0
            return Image.get(self.main_image_id)
        else
            return self.images.first
        end
    end

    # Scopes query for main image existing
    def self.has_main_image
        all(:main_image_id.gt => 0) | all(:product_images.not => nil)
    end

    # Gets batch main images for products
    # TODO: Add override for main_image_id in the product row
    def self.get_main_images(product_ids)
        return [] unless product_ids&.any?
        product_images = $DB.select <<-FOO
            SELECT
                    pi.product_id,
                    pi.image_id,
                    pi.image_order
            FROM (
                    SELECT *
                    FROM product_images
                    ORDER BY image_order ASC LIMIT 18446744073709551615) AS pi
            WHERE
                    pi.product_id IN(#{Array(product_ids).join(',')})
            GROUP BY
                    pi.product_id
        FOO

        images = Image.all(id: product_images.pluck(:image_id))

        return product_images.map do |product| 
            image = images.find{ |e| e.id == product.image_id }
            OpenStruct.new(
                product_id: product.product_id,
                image_url:  image&.url,
                width:      image&.width,
                height:     image&.height,
            )
        end
    end

    # category_id is not actually used anymore - see Category model
    def category() self.options&.category; end
    
    # Gets batch categories for product IDs
    # TODO: Add functionality for grabbing the parent categories
    def self.get_categories(product_ids)
        product_categories = ProductOption.all(fields: [ :product_id, :category_id ], product_id: Array(product_ids), :category_id.gt => 0)
        categories = Category.all(fields: [ :id, :name ], id: product_categories.pluck('category_id'))

        return product_categories.map do |product|
            OpenStruct.new(
                product_id: product.product_id,
                category_id: product.category_id,
                name: (categories.find{ |c| c.id == product.category_id }&.name || ''),
            )
        end
    end

    # NOTE: Taking a shot in the dark here, these fields might all refer to
    #       category as well
    property :store_category_id, Integer, allow_nil: true
    belongs_to :store_category, model: 'Category', child_key: [ :store_category_id ]

    property :store_sub_category_id, Integer, allow_nil: true
    belongs_to :store_sub_category, model: 'Category', child_key: [ :store_sub_category_id ]

    # FIXME: do these map to users?
    # TODO: If so, uncomment the following belongs_to's
    property :customer_id, Integer, allow_nil: true, index: true
    property :supplier_id, Integer, allow_nil: true
    belongs_to :customer, model: 'User', child_key: [ :customer_id ]
    #belongs_to :supplier, model: 'User', child_key: [ :supplier_id ]

    property :depth, Decimal, precision: 10, scale: 2, allow_nil: true, default: 0.00
    property :width, Decimal, precision: 10, scale: 2, allow_nil: true, default: 0.00
    property :height, Decimal, precision: 10, scale: 2, allow_nil: true, default: 0.00
    property :weight, Decimal, precision: 10, scale: 2, allow_nil: true

    # Not used
    # property :rent_per_day, Decimal, precision: 10, scale: 2

    property :rent_per_month, Decimal, precision: 10, scale: 2

    def rent_per_day
        return self.rent_per_month / 30
    end

    # NOTE: Commission must be decimal
    def earned_per_month(commission_percent)
        return self.rent_per_month * commission_percent.to_d
    end

    # NOTE: Commission must be decimal
    def earned_per_day(commission_percent)
        return earned_per_month(commission_percent) / 30
    end

    property :sale_price, Decimal, precision: 12, scale: 2, allow_nil: true
    property :rental_value, Decimal, precision: 10, scale: 2, allow_nil: true

    property :preferred_price, Decimal, precision: 10, scale: 2, allow_nil: true
    property :executive_price, Decimal, precision: 10, scale: 2, allow_nil: true
    property :list_price, Decimal, precision: 10, scale: 2, allow_nil: true

    property :warranty_file, String, length: 150, allow_nil: true
    property :return_policy_file, String, length: 250, allow_nil: true
    property :estimated_ship_date, String, length: 250, allow_nil: true

    property :freight_ship_time, String, length: 100, allow_nil: true
    property :delivery_method, String, length: 100, allow_nil: true

    property :delivery_surcharge, Decimal, precision: 10, scale: 2, allow_nil: true

    property :action_required, Boolean, default: 0
    property :action_required_reason, String, length: 250

    # FIXME: Likely a motherfucking piece of shit stupid dumbshit useless field
    property :added_to_cart, DateTime, allow_nil: true

    property :meta_title, String, length: 200, allow_nil: true
    property :meta_keywords, String, length: 500, allow_nil: true
    property :meta_description, String, length: 1000, allow_nil: true

    property :created_at, DateTime, field: 'created', index: true

    property :delete_reason, Text, allow_nil: true

    property :manufacture_name, String, length: 32
    property :manufacture_number, String, length: 32

    property :deacq_price, Decimal, precision: 10, scale: 2
    property :deacq_date, Date

    property :initials, String, length: 8
    property :reserve_reason, Text

    # Product's site is the site ID of the last storage order it appeared on
    # TODO: Is `.last` sufficient here or do we need to order by ID DESC?
    def site
        OrderLine.all(product_id: self.id, OrderLine.order.type => 'Storage').last.order.site rescue nil
    end

    # Gets batch sites for product ID(s)
    # NOTE: Uses the barcodes table and groups on product ID. If barcodes
    #       for the same product have differing site ID's, this could produce
    #       inconsistent results.
    def self.get_sites(product_ids)
        product_site_ids = Barcode.all(fields: [ :product_id, :site_id ], product_id: Array(product_ids), unique: true, order: nil)
        sites = Site.all(fields: [ :id, :site ], id: product_site_ids.pluck(:site_id).uniq, active: 'Active')

        # Skips invalid products with site ID's (generally due to an issue with barcodes table having invalid site ID)
        product_site_ids_pids = product_site_ids.pluck(:product_id)
        split_site_pids = product_site_ids_pids.select { |e| product_site_ids_pids.count(e) > 1 }.uniq
        $LOG.debug "Products found with split barcode site ID's: [#{split_site_pids.join(', ')}]" if split_site_pids.any?
        product_site_ids.delete_if { |e| e.product_id.among?(split_site_pids) && !e.site_id.among?(sites.pluck(:id)) }
        
        return product_site_ids.map do |product|
            site = sites.find{ |e| e.id == product.site_id }
            OpenStruct.new(
                product_id: product.product_id,
                site_id: site&.id,
                site_name: site&.site,
            )
        end
    end

    has n, :product_pieces
    has n, :barcodes

    has 1, :options, 'ProductOption'

    def premium?() self.options&.is_premium; end
    def closeout?() self.options&.closeout; end
    def discount_rental?() self.options&.discount_rental; end
    def sales_item?() self.options&.sales_item; end

    def self.get_flags(product_ids)
        return ProductOption.all(fields: [ :product_id, :is_premium, :closeout, :discount_rental, :sales_item], product_id: Array(product_ids)).map do |product|
            OpenStruct.new(
                product_id: product.product_id,
                premium?: product.is_premium,
                closeout?: product.closeout,
                discount_rental?: product.discount_rental,
                sales_item?: product.sales_item,
            )
        end
    end

    # Product reserved in a sense that it currently exists in a user's cart
    has 1, :product_reservation
    def self.not_reserved() all( :product_reservation.not => ProductReservation.all() ) end

    # Creates reservation - in a customer's cart (not inventory status)
    # TODO: determine proper pattern for surfacing exceptions from models
    def reserve!(user_id)
        self.product_reservation = ProductReservation.new(user_id: user_id)
        if self.save
            $LOG.info "Product %i reserved by %i." % [self.id, user_id]
        else
            $LOG.error "Product %i NOT reserved by %i. | %s" % [self.id, user_id, self.errors.inspect]
        end
    end

    # Checks if product is reserved (in other user's cart)
    # NOTE: This is different from a product being reserved by its owner (product.reserved).
    def is_reserved?
        return product_reservation.present?
    end

    # Master method to determine if a product is rentable
    def is_rentable?
        self.is_available? && self.for_rent == true
    end

    # Master method to determine if a product is buyable
    def is_buyable?
        self.is_available? && self.for_sale == true
    end
    
    # Master method to determine if a product is available to buy or rent (common logic)
    # Checking for site because some old products don't have a site on their last Storage order (bad data)
    def is_available?
        !self.is_reserved? && self.active == 'Active' && self.site
    end

    has 0..n, :order_lines, 'OrderLine'
    def on_open_order?
        return order_lines.count(
                   OrderLine.order.type => ['Rental', 'Sales'],
                   OrderLine.order.status.not => ['Complete', 'Void'],
                   void: 'no',
                   conditions: [ "(SELECT count(*) FROM `product_piece_locations` WHERE `table_name` = 'orders' AND `table_id` = `orders`.`id` AND `log_type` = 'Returned' AND `product_piece_id` IN (SELECT `product_piece_id` FROM `barcodes` WHERE `product_id` = `order_lines`.`product_id`)) < 1" ],
        ) > 0
    end

    # Sets inventory status (reserved)
    # Status can be: private, rent, rent_sell
    def set_inventory_status!(status, user:)
        pel = ProductEditLog.new
        pel.product_id = id
        pel.action = "storage_status"
        pel.user_id = user.id

        case status
        when 'private'
            self.reserved = true
            self.for_rent = false
            self.for_sale = false
            pel.new_value = "private"         
        when 'rent'
            self.reserved = false
            self.for_rent = true
            self.for_sale = false
            pel.new_value = "rent"
        when 'rent_sell'
            self.reserved = false
            self.for_rent = true
            self.for_sale = true
            pel.new_value = "rent_sell"
        else
            $LOG.error "Invalid status supplied: [product: %i, status: %s]" % [  ]
        end

        if dirty_attributes.keys.map{ |k| k.name }&.any?{ |k| [:reserved, :for_rent, :for_sale].include?(k) }
            old = original_attributes.map { |k,v| [ k.name, v ] }.to_h

            o_reserved = old.fetch(:reserved, reserved)
            o_for_rent = old.fetch(:for_rent, for_rent)
            o_for_sale = old.fetch(:for_sale, for_sale)

            pel.old_value = 'private'   if o_reserved and !o_for_rent and !o_for_sale
            pel.old_value = 'rent'      if !o_reserved and o_for_rent and !o_for_sale
            pel.old_value = 'rent_sell' if !o_reserved and o_for_rent and o_for_sale

            if save
                $LOG.info "Product status changed: [product: %i, private: %s, rent: %s, sale: %s, user: %s]" % [ id, reserved.to_s, for_rent.to_s, for_sale.to_s, user.email ]
                if pel.save
                    $LOG.info "Product Edited: [product: %i, private: %s, rent: %s, sale: %s, user: %s]" % [ id, reserved.to_s, for_rent.to_s, for_sale.to_s, user.email ]
                else
                    $LOG.error "Product Not Edited: [product: %i, private: %s, rent: %s, sale: %s, user: %s] %s" % [ id, reserved.to_s, for_rent.to_s, for_sale.to_s, user.email, pel.errors.inspect ]
                end
                return true
            else
                $LOG.error "Product status NOT changed: [product: %i, private: %s, rent: %s, sale: %s, user: %s] %s" % [ id, reserved.to_s, for_rent.to_s, for_sale.to_s, user.email, errors.inspect ]
                return false
            end
        else
            $LOG.info "Product status already set: [product: %i, private: %s, rent: %s, sale: %s, user: %s] %s" % [ id, reserved.to_s, for_rent.to_s, for_sale.to_s, user.email]
            return true
        end
    end
    
    # Gets the colors and materials for product ID's
    def self.product_options(product_ids)
        return [] if product_ids.empty?
        $DB.select <<-FOO
            SELECT
                yp.product_id,
                yc.id AS category_id,
                yc.name AS category_name,
                yc_parent.id AS parent_category_id,
                yc_parent.name AS parent_category_name,
                yc_child.id AS child_category_id,
                yc_child.name AS child_category_name,
                yoc.id AS color_id,
                yoc.label AS color,
                yom.id AS material_id,
                yom.label AS material,
                yob.id AS bed_size_id,
                yob.label AS bed_size,
                yos.id AS sofa_size_id,
                yos.label AS sofa_size
            FROM
                yuxi_products AS yp
                LEFT JOIN yuxi_categories AS yc ON yp.category_id = yc.id
                LEFT JOIN yuxi_categories AS yc_parent ON yc.parentid = yc_parent.id
                LEFT JOIN yuxi_categories AS yc_child ON yc.id = yc_child.parentid
                LEFT JOIN yuxi_options AS yoc ON yp.color_id = yoc.id
                LEFT JOIN yuxi_options AS yom ON yp.material_id = yom.id
                LEFT JOIN yuxi_options AS yob ON (yp.size_id = yob.id AND yob.tag = 'BED_SIZE')
                LEFT JOIN yuxi_options AS yos ON (yp.size_id = yos.id AND yos.tag = 'SOFA_SIZE')
            WHERE
                yp.product_id IN (#{Array(product_ids).join(',')})
        FOO
    end

    def self.available_products(site_id)
        $DB.select <<-FOO
            SELECT * FROM (SELECT p.id, p.product AS name, p.description, p.width, p.height, p.depth, p.for_sale, p.for_rent,p.reserved,
                rent_per_month, sale_price, sale_price*1.6 AS retail,
                yp.product_id, p.created, p.type, p.quantity,p.box,
                (SELECT name FROM yuxi_categories WHERE id = yp.category_id) AS category_type,
                (SELECT id FROM user_wishlist WHERE product_id = p.id AND user_id = 3149 LIMIT 0,1) AS wishlist,
                (SELECT label FROM yuxi_options WHERE tag = 'COLOR' AND id = yp.color_id) AS color,
                (SELECT label FROM yuxi_options WHERE tag = 'MATERIAL' AND id = yp.material_id) AS material,
                (SELECT label FROM yuxi_options WHERE tag = 'FABRIC' AND id = yp.fabric_id) AS fabric,
                (SELECT label FROM yuxi_options WHERE tag = 'METAL' AND id = yp.texture_id) AS metal,
                (SELECT label FROM yuxi_options WHERE tag = 'SOFA_SIZE' AND id = yp.size_id) AS sofa_size,
                (SELECT label FROM yuxi_options WHERE tag = 'BED_SIZE' AND id = yp.size_id) AS bed_size,
                (SELECT site_id FROM orders WHERE id = loc.table_id) AS site, yp.is_premium
            FROM products AS p
            LEFT JOIN (SELECT MAX(id) as id, product_id FROM product_pieces GROUP BY product_id) pc ON pc.product_id = p.id
            INNER JOIN product_piece_locations loc ON loc.product_piece_id = pc.id AND loc.table_name = 'orders' AND loc.log_type IN ('Available','Received') AND loc.log_status = 'Posted' AND loc.void = 'no'
            LEFT JOIN product_piece_locations loc2 ON loc2.product_piece_id = pc.id AND loc2.table_name = 'orders' AND loc2.log_status = 'Posted' AND loc2.void = 'no' AND loc2.id > loc.id
            LEFT JOIN yuxi_products AS yp ON p.id = yp.product_id
            WHERE loc2.id IS NULL
                    AND (yp.category_id IN (SELECT id FROM yuxi_categories WHERE parentid = 41))
                    AND ((p.for_sale = 1 AND p.sale_price > 0) OR (p.for_rent = 1 AND p.rent_per_month > 0))
                    AND (added_to_cart IS NULL OR added_to_cart < DATE_SUB(NOW(), INTERVAL 2 HOUR))
                    AND (('For Rent' = 'For Both' AND (p.for_sale = 1 OR p.for_rent = 1)) OR ('For Rent' = 'For Rent' AND p.for_rent = 1) OR ('For Rent' = 'For Sale' AND p.for_sale = 1))
                    AND (p.active = 'Active')) AS temp
            WHERE site = #{site_id}
            ORDER BY rent_per_month ASC, sale_price ASC
        FOO
    end

    # Gets the product status that's displayed in user's inventory
    def self.status_for_user_inventory(product_ids)
        return [] if product_ids.empty?

        constraint = "IN (#{Array(product_ids).join(',')})"

        result = $DB.select <<-FOO
            SELECT
                p.id,
                CASE
                    WHEN loc.log_type IN ('Available','Received') THEN 'Available'
                    WHEN o.type = 'Sales' THEN 'Purchased'
                    WHEN o.type = 'Rental' THEN 'Rented'
                    WHEN o.type = 'Return' THEN 'Rented'
                    WHEN o.type = 'TransferToShop' AND loc.log_type = 'Transfered' THEN 'Available'
                    ELSE 'Unavailable'
                END AS status
            FROM products AS p
            LEFT JOIN product_pieces AS pc ON pc.product_id = p.id
            LEFT JOIN product_piece_locations AS loc ON loc.product_piece_id = pc.id AND loc.table_name = 'orders' AND loc.log_status = 'Posted' AND loc.void != 'yes'
            LEFT JOIN product_piece_locations AS loc2 ON loc2.product_piece_id = pc.id AND loc2.table_name = 'orders' AND loc2.log_status = 'Posted' AND loc2.void != 'yes' AND loc2.id > loc.id
            LEFT JOIN orders o ON o.id = loc.table_id
            LEFT JOIN order_lines ol ON ol.product_id = p.id
            LEFT JOIN orders o2 ON o2.id = ol.order_id AND o2.type = 'Storage'
            LEFT JOIN product_piece_locations sloc ON sloc.product_piece_id = pc.id AND sloc.table_name = 'orders' AND sloc.table_id = o2.id AND sloc.log_status = 'Posted' AND sloc.log_type = 'Available' AND sloc.void != 'yes'
            LEFT JOIN product_piece_locations sloc2 ON sloc2.product_piece_id = pc.id AND sloc2.table_name = 'orders' AND sloc.table_id = o2.id AND sloc2.log_status = 'Posted' AND sloc.log_type = 'Available' AND sloc2.void != 'yes' AND sloc2.id > sloc.id
            WHERE
                loc2.id IS NULL
                AND p.type != 'Store'
                AND p.id #{constraint}
            GROUP BY p.id
        FOO

        return result
    end

    # Gets purchased products by user
    # TODO: Sale price should come from the order lines, not from the product sale price
    def self.purchased_products_for_user_inventory(user_id, status='NULL', offset=0, limit=100)
        result = $DB.select <<-FOO
            SELECT p.id,loc.created AS last_log_date,
                IFNULL((SELECT att.attribute FROM product_attributes patt
                    LEFT JOIN attributes att ON att.id = patt.attribute_id
                    WHERE att.type <> 'Bumped and Bruised' AND att.type <> 'Vignettes'
                        AND patt.product_id = p.id
                    GROUP BY patt.product_id), 'Uncategorized') as furniture_attribute,
                CASE WHEN loc.log_type = 'Available' THEN 'Available'
                    WHEN o.type = 'Sales' OR o.type = 'Rental' THEN
                    CASE WHEN ol.void = 'yes' THEN 'Cancelled'
                            WHEN loc.log_type = 'OnOrder' THEN 'On Order'
                            WHEN loc.log_type = 'Pulled' AND o.service = 'Company' THEN 'Processed For Shipping'
                            WHEN loc.log_type = 'Pulled' AND o.service = 'Self' THEN 'Ready For Pick-up'
                            WHEN loc.log_type = 'InTransit' THEN 'Shipping'
                            WHEN loc.log_type = 'Shipped' AND o.service = 'Company' THEN 'Delivered'
                            WHEN loc.log_type = 'Shipped' AND o.service = 'Self' THEN 'Picked-up'
                            WHEN loc.log_type = 'Returned' THEN 'Returned'
                            ELSE 'Unknown' END
                    WHEN o.type = 'Return' THEN 'Available'
                    WHEN o.type = 'TransferToShop' THEN 'Available'
                    ELSE 'Unavailable' END as status,
                o.ordered_date,
                ol.void, loc.log_type, CASE WHEN ol.void = 'no' THEN loc.created ELSE ol.voided_date END AS log_date,
                ol.base_price, o2.id AS current_order_id
            FROM products p
            LEFT JOIN categories c on c.id = p.category_id
            LEFT JOIN product_images i ON i.product_id = p.id AND i.image_order = 1
            LEFT JOIN image_library l ON l.id = i.image_id
            INNER JOIN product_pieces pc ON pc.product_id = p.id
            INNER JOIN product_piece_locations loc ON loc.table_name = 'orders' AND loc.product_piece_id = pc.id AND (NULL IS NULL OR loc.table_id = NULL)
                AND loc.id = (SELECT MAX(id) FROM product_piece_locations l2 WHERE l2.product_piece_id = pc.id AND table_name = 'orders' AND (NULL IS NULL OR table_id = NULL) AND log_status = 'Posted' AND (((#{status} IS NULL OR #{status} != 'Void') AND l2.void != 'yes') OR l2.void = 'yes'))
            LEFT JOIN orders o ON loc.table_id = o.id
            LEFT JOIN order_lines ol ON ol.order_id = o.id AND ol.product_id = p.id
            LEFT JOIN product_attributes patt ON patt. product_id = p.id
            LEFT JOIN attributes att ON att.id = patt.attribute_id AND att.type <> 'Bumped and Bruised' AND att.type <> 'Vignettes'
            LEFT JOIN product_piece_locations loc2 ON loc2.table_name = 'orders' AND loc.product_piece_id = pc.id
                AND loc2.id = (SELECT MAX(id) FROM product_piece_locations l2 WHERE l2.product_piece_id = pc.id AND table_name = 'orders' AND log_status = 'Posted' AND (((#{status} IS NULL OR #{status} != 'Void') AND l2.void != 'yes') OR l2.void = 'yes'))
            LEFT JOIN orders o2 ON o2.id = loc2.table_id
            WHERE o.user_id = #{user_id}
            AND (o.type = 'Sales')
            AND (NULL IS NULL OR
                ('Uncategorized' = NULL AND (SELECT pa.id FROM product_attributes pa LEFT JOIN attributes a ON pa.attribute_id = a.id WHERE a.type = 'Furniture' AND pa.product_id = p.id) IS NULL
                AND  (SELECT pa.id FROM product_attributes pa LEFT JOIN attributes a ON pa.attribute_id = a.id WHERE a.type = 'Accessory' AND pa.product_id = p.id) IS NULL ) OR
                        (SELECT pa.id FROM product_attributes pa LEFT JOIN attributes a ON pa.attribute_id = a.id WHERE a.id = NULL AND pa.product_id = p.id) IS NOT NULL)
            AND (#{status} IS NULL OR (loc.log_type = #{status} AND ol.void != 'yes') OR (#{status} = 'Void' AND ol.void = 'yes') OR (#{status} = 'OnOrder' AND loc.log_type IN ('OnOrder','Pulled','InTransit') AND ol.void != 'yes'))
            AND (NULL IS NULL OR o.id = NULL)
            AND p.type != 'NonStock'
            GROUP BY p.id
            LIMIT #{offset}, #{limit}
        FOO
    end

    # Gets rental income report for user
    # NOTE: We switched commission methodologies on September 1, 2018 so we're not
    #       providing reporting prior to that day.
    def self.rental_income_for_user(user, year:nil, month:nil)
        user_id = user.id rescue user.to_i
        year = Date.today.year unless year&.to_i.in? (2010..Date.today.year)
        month = Date.today.month unless month&.to_i.in? (1..12)
        date = "#{year}-#{month}-01".to_date

        # Limits reporting to 9/1/18 (see note)
        return [] if date < "2018-09-01".to_date

        # Gets historical commissions if date requested is prior to current month
        if date.strftime('%Y-%m') == Date.today.strftime('%Y-%m')
            return $DB.select <<-FOO
                SELECT p.id, p.product, ol.base_price, i.image,
                    DATE_FORMAT(l.created,'%b %d, %Y') AS start_date,
                    DATE_FORMAT(l2.created,'%b %d, %Y') AS end_date,
                    DATE_FORMAT(l.created,'%Y-%m-%d') AS from_date,
                    DATE_FORMAT(l2.created,'%Y-%m-%d') AS to_date
                FROM products p
                INNER JOIN (SELECT MAX(id) AS id, product_id FROM product_pieces GROUP BY product_id) pp ON pp.product_id = p.id
                INNER JOIN product_piece_locations l ON l.product_piece_id = pp.id AND l.log_type = 'Shipped' AND l.log_status = 'Posted' AND l.void != 'yes'
                INNER JOIN orders o ON o.id = l.table_id AND l.table_name = 'orders' AND o.type = 'Rental'
                INNER JOIN order_lines ol ON ol.order_id = o.id AND ol.product_id = p.id AND ol.void != 'yes' AND (l.order_line_id IS NULL OR l.order_line_id = ol.id)
                LEFT JOIN product_piece_locations l2 ON l2.product_piece_id = l.product_piece_id AND l2.table_name = 'orders' AND l2.log_type = 'Returned' AND l2.log_status = 'Posted' AND l2.void != 'yes' AND l2.id > l.id AND (l2.order_line_id IS NULL OR l2.order_line_id = ol.id)
                LEFT JOIN product_piece_locations l2neg ON l2neg.product_piece_id = l2.product_piece_id AND l2neg.table_name = 'orders' AND l2neg.log_type = 'Returned' AND l2neg.log_status = 'Posted' AND l2neg.void != 'yes' AND l2neg.id > l.id AND l2neg.id < l2.id AND (l2neg.order_line_id IS NULL OR l2neg.order_line_id = ol.id)
                LEFT JOIN (SELECT image_id,product_id FROM product_images GROUP BY product_id ORDER BY image_order ASC) AS pi ON pi.product_id = p.id
                LEFT JOIN image_library i ON i.id = pi.image_id
                LEFT JOIN users AS u ON u.id = p.customer_id
                WHERE o.user_id <> p.customer_id
                AND l2neg.id IS NULL
                AND ol.refunded != 'Yes'
                AND p.customer_id = #{user_id}
                AND ((MONTH(l.created) <= #{month} OR YEAR(l.created) < #{year}) AND (l2.created IS NULL OR (MONTH(l2.created) >= #{month} AND YEAR(l2.created) >= #{year}))) AND (YEAR(l.created) <= #{year} AND (l2.created IS NULL OR YEAR(l2.created) >=#{year}))
            FOO
        else
            return $DB.select <<-FOO
                SELECT p.id, p.product, FORMAT(c.commission,2) AS commission, i.image, c.base_price,
                    DATE_FORMAT(c.start_date,'%b %d, %Y') AS start_date,
                    DATE_FORMAT(c.end_date,'%b %d, %Y') AS end_date,
                    DATE_FORMAT(c.start_date,'%Y-%m-%d') AS from_date,
                    DATE_FORMAT(c.end_date,'%Y-%m-%d') AS to_date
                FROM commission AS c
                LEFT JOIN products AS p ON p.id = c.product_id
                LEFT JOIN sites AS s ON s.id = c.location_id
                LEFT JOIN (SELECT image_id,product_id FROM product_images GROUP BY product_id ORDER BY image_order ASC) AS pi ON pi.product_id = p.id
                LEFT JOIN image_library i ON i.id = pi.image_id
                WHERE c.cycle = '#{date}' AND c.customer_id = #{user_id} AND c.type = 'RENT'
            FOO
        end
    end

    # Fixes shitty character encoding for product name
    def self.fix_encoding(product_id)
        p = Product.get(product_id)
        old = p.product
        new = p.product = p.product.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
        
        if p.save
            $LOG.info "Name character encoding updated for product: %i [old: %s, new: %s]" % [ product_id, old, new ]
        else
            $LOG.info "Name character encoding NOT updated for product: %i [old: %s, new: %s] %s" % [ product_id, old, new, p.errors.inspect ]
        end

        return p.product
    end

    def last_returned_at
        return nil if on_open_order?

        last_returned_at = $DB.select <<-FOO
            SELECT ppl.created
            FROM product_piece_locations AS ppl
            INNER JOIN orders AS o ON (ppl.table_name = 'orders' AND ppl.table_id = o.id AND o.type = 'Rental' AND ppl.log_type = 'Returned')
            WHERE product_piece_id IN(SELECT id FROM product_pieces WHERE product_id = #{id}) AND ppl.void = 'no'
            ORDER BY ppl.id DESC LIMIT 1
        FOO

        # Product hasn't been on an order - get its initial storage order creation date
        unless last_returned_at.any?
            last_returned_at = $DB.select <<-FOO
                SELECT o.complete_date
                FROM product_pieces AS pp 
                LEFT JOIN order_lines AS ol ON pp.order_line_id = ol.id
                LEFT JOIN orders AS o ON ol.order_id = o.id
                WHERE pp.product_id = #{id}
                ORDER BY o.id DESC LIMIT 1;
            FOO
        end

        return last_returned_at.first
    end

    def days_since_last_returned
        return (Date.today - last_returned_at).to_i rescue 0
    end

    # Gets recently returned products
    def self.recently_returned(amount: 10, site_id: 24)
        filters = {
            site_id:           site_id,
            intent:            "rent",
            sort:              'rrp',
            hide_reserved:     true,
            hide_no_image:     true,
            hide_red_tag_bin:  true,
            hide_hidden_bin:   true,
            hide_ps_bins:      true,
        }
        all_product_ids = Barcode.available_product_ids(filters)
        product_ids = all_product_ids[0, amount]
        return Product.all(id: product_ids)
    end
    
    def self.search_id_name(query)
        return all() unless query
        return all(id: query&.to_i) |
               all(:product.like => "%#{query}%")
    end
    
end

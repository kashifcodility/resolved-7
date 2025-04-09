class Cart
    include ::DataMapper::Resource

    property :id, Serial

    belongs_to :user

    property :address_id, Integer, allow_nil: true
    belongs_to :address, required: false
    alias_method :shipping_address, :address

    property :tax_authority_id, Integer, allow_nil: true
    belongs_to :tax_authority

    property :items, Json, default: [], lazy: false # https://github.com/datamapper/dm-types/issues/77
    property :subtotal, Decimal, precision: 10, scale: 2, default: 0.00
    property :total, Decimal, precision: 10, scale: 2, default: 0.00
    
    # Saves state of checkout process for multi-step checkout
    property :checkout, Json, default: {}, lazy: false
    
    timestamps :at 

    # Add item to cart
    def add_item(product, intent,room_id, self_rental_commission)
        if product.on_open_order?
            $LOG.debug "Item NOT added to cart - exists on open order: [product: %i, intent: %s, user: %s]" % [ product.id, intent, user&.email ]
            Return false
        end
        
        if intent == 'buy'
            price = product.sale_price
        else
            price = product.rent_per_month
            if self_rental_commission
                commission_percent = Fee.self_rental_commission
                price = (price * commission_percent).round(2)
            end
        end

        product.added_to_cart = Time.zone.now
        product.save

        self.items ||= []
        self.items.map!(&:symbolize_keys) << {
            id: product.id,
            intent: intent,
            price: price,
            room_id: room_id,
        }

        self.subtotal = self.calculate_subtotal
    end

    # Gets items currently in cart
    # Merges the items currently in the cart with their respective product models.
    # TODO: Convert this to an OpenStruct
    def get_items
        return [] unless self.items.present?

        cart_product_ids = items.pluck('id')

        product_sites = Product.get_sites(cart_product_ids)
        product_main_images = Product.get_main_images(cart_product_ids)
        product_models = Product.all(fields: [ :id, :active, :product ], id: cart_product_ids)

        return product_models.map do |product|
            cart_product = items.find{ |e| e['id'] == product.id }.symbolize_keys
            cart_product.merge({
                active:         product.active,
                product:        product.name,
                name:           product.name,
                site_id:        product_sites.find{ |e| e.product_id == product.id }&.site_id, 
                main_image_url: product_main_images.find{ |e| e.product_id == product.id}&.image_url,
                is_favorite:    user.favorites.pluck(:id).include?(product.id),
            })
        end
    end

    # Item exists in cart?
    def item_in_cart?(product)
        id = product.is_a?(Product) ? product.id : product.to_i
        self.items.find { |i| i['id'] == id }.present?
    end

    # Remove item
    def destroy_item!(id)
        self.items.delete_if { |i| i['id'] == id.to_i }
        self.calculate_subtotal
        if self.save
            $LOG.info "Product %i successfully removed from cart." % [id]

            product = Product.get(id)
            product.added_to_cart = nil
            product.save
            
            return true
        else
            $LOG.error "Product %i NOT removed from cart. | %s" % [id, self.errors.inspect]
            return false
        end
    end

    # Destroy the cart model and wipe out user's product reservations
    # Theoretically, the wiping of reservations shouldn't be used. Safeguard.
    def destroy!
        errant_reservations = ProductReservation.all(user: self.user)
        er_count = errant_reservations.count
        if er_count > 0
            if errant_reservations.destroy!
                $LOG.info "Destroyed %i errant product reservations for user %s (cart %i)." % [er_count, self.user.email, self.id]
            else
                $LOG.error "Error destroying %i errant product reservations for user %s (cart %i). | %s" % [er_count, self.user.email, self.id, errant_reservations.errors.inspect]
            end
        end

        super
    end

    # Subtotal of all the items
    # TODO: Nuke this - don't think it's used, but need to confirm
    def calculate_subtotal
        self.items.pluck(:price).map(&:to_d).sum.round(2)
    end

    def has_rent_items?
        item_intents.include?('rent')
    end

    def has_buy_items?
        item_intents.include?('buy')
    end
    
    def item_intents
        get_items.pluck(:intent).uniq
    end
    
end

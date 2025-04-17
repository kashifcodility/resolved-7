class Cart < ApplicationRecord
    # property :id, Serial

    # belongs_to :user

    # property :address_id, Integer, allow_nil: true
    # belongs_to :address, required: false
    # alias_method :shipping_address, :address

    # property :tax_authority_id, Integer, allow_nil: true
    # belongs_to :tax_authority

    # property :items, Json, default: [], lazy: false # https://github.com/datamapper/dm-types/issues/77
    # property :subtotal, Decimal, precision: 10, scale: 2, default: 0.00
    # property :total, Decimal, precision: 10, scale: 2, default: 0.00

    # # Saves state of checkout process for multi-step checkout
    # property :checkout, Json, default: {}, lazy: false

    # timestamps :at
    # after_initialize :initialize_items

    belongs_to :user
    belongs_to :address, optional: true
    alias_method :shipping_address, :address
    belongs_to :tax_authority, optional: true

    # serialize :items, JSON
    # serialize :checkout, JSON

    # Add item to cart
    def add_item(product, intent, room_id, quantity, self_rental_commission=false)
        # if product.on_open_order?
        #     Rails.logger.debug "Item NOT added to cart - exists on open order: [product: %i, intent: %s, user: %s]" % [ product.id, intent, user&.email ]
        #     Return false
        # end

        if intent == 'buy'
            price = product.rating_price_sale
        else
            price = product.rating_price_rent
            # if self_rental_commission
            #     commission_percent = Fee.self_rental_commission
            #     price = (price * commission_percent).round(2)
            # end
        end

        product.added_to_cart = Time.zone.now
        product.save
        cart_items = eval(self.items) if self.items.present?
        # self.items ||= []
        # binding.pry
        if cart_items.present?
            cart_items << {
                id: product.id,
                uniq_id: SecureRandom.hex,
                intent: intent,
                price: price,
                room_id: room_id,
                quantity: quantity,
            }
        else
            cart_items = [{
                id: product.id,
                uniq_id: SecureRandom.hex,
                intent: intent,
                price: price,
                room_id: room_id,
                quantity: quantity,
            }]
        end        
        self.items = cart_items
        self.subtotal = self.calculate_subtotal
    end

   

    # Gets items currently in cart
    # Merges the items currently in the cart with their respective product models.
    # TODO: Convert this to an OpenStruct
    def get_items
        return [] unless self.items.present?
        cart_items = eval(self.items)
        cart_product_ids = cart_items.pluck(:id)

        product_sites = Product.get_sites(cart_product_ids)
        product_main_images = Product.get_main_images(cart_product_ids)
        # product_models = Product.all(fields: [ :id, :active, :product ], id: cart_product_ids)

        all_items =  cart_items.map do |i|
            # binding.pry
            product = Product.find_by(id: i[:id])
            cart_product = i
            cart_product.merge({
                active:         product.active,
                product:        product.name,
                name:           product.name,
                site_id:        product.site_id,
                main_image_url: product_main_images.find{ |e| e.product_id == product.id}&.image_url,
                is_favorite:    user.favorites&.compact&.pluck(:id)&.include?(product.id),
            })
        end

        all_items
    end

    # Item exists in cart?
    def item_in_cart?(product)
        id = product.is_a?(Product) ? product.id : product.to_i
        # self.items.find { |i| i['id'] == id }.present?
        cart_items = eval(self.items) if self.items.present?

        # binding.pry
        
        cart_items.present? && cart_items.any? { |item| item[:id] == id }

    end

    def item_quantity_remaining?(quantity, remaining_quantity, product)
        total_quantity = 0
        total_quantity = self.items.map {|i| i['quantity'].to_i if i['id'] == product }.compact.sum
        total_quantity += quantity.to_i
        total_quantity <= remaining_quantity.to_i ? false : true
    end    

    def destroy_item!(id)
        cart_items = eval(self.items) if self.items.present?    
        cart_items.delete_if { |i| i[:id] == id.to_i }
        self.calculate_subtotal
        if self.save
            Rails.logger.info "Product %i successfully removed from cart." % [id]

            product = Product.find(id)
            product.added_to_cart = nil
            product.save
            
            return true
        else
            Rails.logger.error "Product %i NOT removed from cart. | %s" % [id, self.errors.inspect]
            return false
        end
    end

    # Remove item
    def self.destroy_item_from_cart!(cart, uniq_id, product_id)
        remianing_items = cart.items.delete_if { |i| i[:uniq_id] == uniq_id }
        cart_model = cart.instance_variable_get(:@cart_model)
        if cart_model.update(items: remianing_items)
            Rails.logger.info "Product %i successfully removed from cart." % [product_id]

            product = Product.find(product_id)
            product.added_to_cart = nil
            product.save

            return true
        else
            Rails.logger.error "Product %i NOT removed from cart. | %s" % [product_id, self.errors.inspect]
            return false
        end
    end

    # Destroy the cart model and wipe out user's product reservations
    # Theoretically, the wiping of reservations shouldn't be used. Safeguard.
    def destroy!
        errant_reservations = ProductReservation.where(user: self.user)
        er_count = errant_reservations.count
        if er_count > 0
            if errant_reservations.destroy!
                Rails.logger.info "Destroyed %i errant product reservations for user %s (cart %i)." % [er_count, self.user.email, self.id]
            else
                Rails.logger.error "Error destroying %i errant product reservations for user %s (cart %i). | %s" % [er_count, self.user.email, self.id, errant_reservations.errors.inspect]
            end
        end

        super
    end

    # Subtotal of all the items
    # TODO: Nuke this - don't think it's used, but need to confirm
    def calculate_subtotal
        cart_items = eval(self.items)
        cart_items.pluck(:price).map(&:to_d).sum.round(2)
    end

    def has_rent_items?
        item_intents.include?('rent')
    end

    def has_buy_items?
        item_intents.include?('buy')
    end

    def item_intents
        get_items.map { |i| i[:intent] }.uniq
    end
end

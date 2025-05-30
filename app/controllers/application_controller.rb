# require 'sdn/rails/controller'
# require 'sdn/cart'

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern



  # include ::SDN::Rails::Controller
  # include ::SDN::Rails::Helpers::Session


  include ApplicationHelper

  before_action :get_cart
  before_action :load_order_status
  before_action :check_paid_status


  helper :all # import them all into views
  layout "application"

  ##
  ## Utility Methods for all controllers (and helpers)
  ##

  # Initialize the Cart class if the cart model association exists
  # Avoids creating a cart model until an item is added to the cart
  def load_order_status
    #   if current_user
    #       filters = {
    #               required:         { user_id: current_user.id, :ordered_date.not => nil, order: :id.desc }.freeze,
    #               open:             { order_type: 'Rental', status: 'Open' }.freeze,
    #               pulled:           { order_type: 'Rental', status: 'Pulled' }.freeze,
    #               loaded:           { order_type: 'Rental', status: 'Loaded' }.freeze,
    #               renting:          { order_type: 'Rental', status: 'Renting' }.freeze,
    #               void:             { order_type: 'Rental', status: 'Void', }.freeze,
    #               complete:         { order_type: 'Rental', status: 'Complete' }.freeze,
    #               default:          { order_type: 'Rental', status: [ 'Open', 'Renting', 'Pulled' ] }.freeze,
    #               destage:          { order_type: 'Rental', status: 'Destage', }.freeze,
    #               sales:            { order_type: 'Sales', :status.not => 'Void' }.freeze,
    #           }
      
    #           compiled_filters = filters[:required].dup
      
    #           if params[:cc]
    #               cc = CreditCard.first(id: params[:cc].to_i, user: current_user)
    #               compiled_filters[:credit_card] = cc
    #           end
      
    #           @active_filter = params.fetch(:status, :default).to_sym
              
    #           compiled_filters.merge!(filters.fetch(@active_filter, filters[:default]))
      
    #           @orders = Order.all(compiled_filters).map do |o|
    #               OpenStruct.new(
    #                   id:                 o.id,
    #                   order_type:               o.order_type,
    #                   due_date:           o.due_date,
    #                   email:              o&.user&.email,
    #                   levels:             o.levels,
    #                   company_service:    o.service,
    #                   dwelling:           o.dwelling,
    #                   parking:            o.parking,
    #                   delivery_special_considerations:  o.delivery_special_considerations,
    #                   status:             o.sales? ? 'Complete' : o.status,
    #                   project_name:       o.project_name || o.shipping_address&.address1,
    #                   address:            o.shipping_address,
    #                   ordered_on:         o.ordered_date.to_date,
    #                   delivering_on:      o.due_date&.to_date,
    #                   delivered_on:       o.shipped_at&.to_date,
    #                   destaging_on:       o.destaging_at&.to_date,
    #                   pickup?:            o.pickup?,
    #                   first_billed_on:    o.first_billed_on,
    #                   first_billing_cycle_ends_on: o.first_billing_cycle_ends_on,
    #                   renewal_date:       Order.next_rental_renewal_date(o.ordered_date.to_date, o.shipped_at&.to_date),
    #                   cancellable?:       o.cancellable_by_customer?,
    #                   destageable?:       o.can_be_destaged?,
    #                   destage_requested?: !!o.destage_date,
    #                   cc:                 o.credit_card,
    #                   furniture_subtotal: o.order_lines.product_lines.pluck(:base_price).sum.to_d,
    #                   is_frozen?:         o.frozen? || o.shipped?,
    #                   model:              o,
    #               )
    #           end
    #           @soonest_destage_date = Order.soonest_destage_date
      
    #           # Get totals for each filter
    #           @filter_counts = {
    #               open:             Order.count(filters[:required].merge(filters[:open])).to_i,
    #               renting:          Order.count(filters[:required].merge(filters[:renting])).to_i,
    #               void:             Order.count(filters[:required].merge(filters[:void])).to_i,
    #               complete:         Order.count(filters[:required].merge(filters[:complete])).to_i,
    #               pulled:           Order.count(filters[:required].merge(filters[:pulled])).to_i,
    #               loaded:           Order.count(filters[:required].merge(filters[:loaded])).to_i,
    #               destage:          Order.count(filters[:required].merge(filters[:destage])).to_i,
    #               sales:            Order.count(filters[:required].merge(filters[:sales])).to_i,
    #           }

              
    #           if current_user&.location_rights == "ALL"
    #               site_id = Site.all.pluck(:id)
    #           else  
    #               site_id= Site.all(id: current_user&.location_rights&.split(','))&.pluck(:id)
    #           end
             
    #           @recently_returned = Product.recently_returned(amount: 7, site_id: site_id)
    #   end
    

    # def load_order_status
        if current_user
          # ✅ Converted filters to ActiveRecord style
          filters = {
            required: { user_id: current_user.id }.freeze,
            open:     { order_type: 'Rental', status: 'Open' }.freeze,
            pulled:   { order_type: 'Rental', status: 'Pulled' }.freeze,
            loaded:   { order_type: 'Rental', status: 'Loaded' }.freeze,
            renting:  { order_type: 'Rental', status: 'Renting' }.freeze,
            void:     { order_type: 'Rental', status: 'Void' }.freeze,
            complete: { order_type: 'Rental', status: 'Complete' }.freeze,
            default:  { order_type: 'Rental', status: ['Open', 'Renting', 'Pulled'] }.freeze,
            destage:  { order_type: 'Rental', status: 'Destage' }.freeze,
            sales:    { order_type: 'Sales' }.freeze # :status.not => 'Void' handled below
          }
      
          compiled_filters = filters[:required].dup
      
          # ✅ ActiveRecord-style: find_by instead of first with filter
          if params[:cc]
            cc = CreditCard.find_by(id: params[:cc].to_i, user: current_user)
            compiled_filters[:credit_card_id] = cc&.id # ActiveRecord: use foreign key (id), not object
          end
      
          @active_filter = params.fetch(:status, :default).to_sym
          compiled_filters.merge!(filters.fetch(@active_filter, filters[:default]))
      
          # ✅ Additional filter logic for :required case - moved from DM-style :ordered_date.not => nil
          orders_scope = Order.where(compiled_filters).order(id: :desc)
          orders_scope = orders_scope.where.not(ordered_date: nil) if @active_filter == :required
      
          # ✅ Sort by ID descending (from :order => :id.desc)
          orders_scope = orders_scope.order(id: :desc) if @active_filter == :required
      
          # ✅ Map orders to OpenStruct
          @orders = orders_scope.map do |o|
            OpenStruct.new(
              id:                        o.id,
              order_type:                o.order_type,
              due_date:                  o.due_date,
              email:                     o&.user&.email,
              levels:                    o.levels,
              company_service:           o.service,
              dwelling:                  o.dwelling,
              parking:                   o.parking,
              delivery_special_considerations: o.delivery_special_considerations,
              status:                    o.sales? ? 'Complete' : o.status,
              project_name:              o.project_name || o.shipping_address&.address1,
              address:                   o.shipping_address,
              ordered_on:                o.ordered_date.to_date,
              delivering_on:             o.due_date&.to_date,
              delivered_on:              o.shipped_at&.to_date,
              destaging_on:              o.destaging_at&.to_date,
              pickup?:                   o.pickup?,
              first_billed_on:           o.first_billed_on,
              first_billing_cycle_ends_on: o.first_billing_cycle_ends_on,
              renewal_date:              Order.next_rental_renewal_date(o.ordered_date.to_date, o.shipped_at&.to_date),
              cancellable?:              o.cancellable_by_customer?,
              destageable?:              o.can_be_destaged?,
              destage_requested?:        !!o.destage_date,
              cc:                        o.credit_card,
              furniture_subtotal:        o.order_lines.product_lines.pluck(:base_price).sum.to_d,
              is_frozen?:                o.frozen? || o.shipped?,
              model:                     o
            )
          end
      
          @soonest_destage_date = Order.soonest_destage_date
      
          # ✅ Update count logic: ActiveRecord syntax
          @filter_counts = {
            open:     Order.where(filters[:required]).where(filters[:open]).where.not(ordered_date: nil).count,
            renting:  Order.where(filters[:required]).where(filters[:renting]).where.not(ordered_date: nil).count,
            void:     Order.where(filters[:required]).where(filters[:void]).where.not(ordered_date: nil).count,
            complete: Order.where(filters[:required]).where(filters[:complete]).where.not(ordered_date: nil).count,
            pulled:   Order.where(filters[:required]).where(filters[:pulled]).where.not(ordered_date: nil).count,
            loaded:   Order.where(filters[:required]).where(filters[:loaded]).where.not(ordered_date: nil).count,
            destage:  Order.where(filters[:required]).where(filters[:destage]).where.not(ordered_date: nil).count,
            # ✅ 'sales' filter: adding .where.not(status: 'Void') inline
            sales:    Order.where(filters[:required]).where(filters[:sales]).where.not(status: 'Void').where.not(ordered_date: nil).count
          }
      
          # ✅ ActiveRecord fix for site logic
          if current_user&.location_rights == "ALL"
            site_id = Site.all.pluck(:id)
          else
            site_ids = current_user&.location_rights&.split(',')&.map(&:to_i)
            site_id = Site.where(id: site_ids).pluck(:id)
          end
      
          # Assuming Product.recently_returned is already scoped properly
          @recently_returned = Product.recently_returned(amount: 7, site_id: site_id)
        end
    #   end
  end


  def check_paid_status
    exempt_paths = [logout_path, pay_path, login_path, signup_path, register_site_path, 
                    payments_success_path, payments_cancel_path, stripe_checkout_path ]
    #  binding.pry
    return if exempt_paths.include?(request.path)
    if current_user && current_user.subscription_expired?
      redirect_to pay_path
    end
  end



           
  def get_cart
    #   binding.pry
      if current_user && current_user.cart
          
          @cart = ::Sdn::Cart.new(current_user)
          
      end
  end

  ##
  ## JSON response helpers
  ##

  def json_response(success:, message:, data: {})
      return render(json: { success: success, message: message, data: data })
  end

  def json_success(message = 'Request successful.', data: {})
      return json_response(success: true, message: message, data: data)
  end

  def json_error(message = 'Request unsuccessful.', data: {})
      return json_response(success: false, message: message, data: data)
  end

  # All standard ones are in app/helpers/application_helpers.rb

  ##
  ## Filters & Exception handling (e.g. before...)
  ##














end

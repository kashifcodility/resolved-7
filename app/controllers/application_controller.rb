# require 'sdn/rails/controller'
# require 'sdn/cart'

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern



  # include ::SDN::Rails::Controller
  # include ::SDN::Rails::Helpers::Session


  include ApplicationHelper

  # before_action :get_cart
  # before_action :load_order_status

  helper :all # import them all into views
  layout "application"

  ##
  ## Utility Methods for all controllers (and helpers)
  ##

  # Initialize the Cart class if the cart model association exists
  # Avoids creating a cart model until an item is added to the cart
  def load_order_status
      if current_user
          filters = {
                  required:         { user_id: current_user.id, :ordered_date.not => nil, order: :id.desc }.freeze,
                  open:             { order_type: 'Rental', status: 'Open' }.freeze,
                  pulled:           { order_type: 'Rental', status: 'Pulled' }.freeze,
                  loaded:           { order_type: 'Rental', status: 'Loaded' }.freeze,
                  renting:          { order_type: 'Rental', status: 'Renting' }.freeze,
                  void:             { order_type: 'Rental', status: 'Void', }.freeze,
                  complete:         { order_type: 'Rental', status: 'Complete' }.freeze,
                  default:          { order_type: 'Rental', status: [ 'Open', 'Renting', 'Pulled' ] }.freeze,
                  destage:          { order_type: 'Rental', status: 'Destage', }.freeze,
                  sales:            { order_type: 'Sales', :status.not => 'Void' }.freeze,
              }
      
              compiled_filters = filters[:required].dup
      
              if params[:cc]
                  cc = CreditCard.first(id: params[:cc].to_i, user: current_user)
                  compiled_filters[:credit_card] = cc
              end
      
              @active_filter = params.fetch(:status, :default).to_sym
              
              compiled_filters.merge!(filters.fetch(@active_filter, filters[:default]))
      
              @orders = Order.all(compiled_filters).map do |o|
                  OpenStruct.new(
                      id:                 o.id,
                      order_type:               o.order_type,
                      due_date:           o.due_date,
                      email:              o&.user&.email,
                      levels:             o.levels,
                      company_service:    o.service,
                      dwelling:           o.dwelling,
                      parking:            o.parking,
                      delivery_special_considerations:  o.delivery_special_considerations,
                      status:             o.sales? ? 'Complete' : o.status,
                      project_name:       o.project_name || o.shipping_address&.address1,
                      address:            o.shipping_address,
                      ordered_on:         o.ordered_date.to_date,
                      delivering_on:      o.due_date&.to_date,
                      delivered_on:       o.shipped_at&.to_date,
                      destaging_on:       o.destaging_at&.to_date,
                      pickup?:            o.pickup?,
                      first_billed_on:    o.first_billed_on,
                      first_billing_cycle_ends_on: o.first_billing_cycle_ends_on,
                      renewal_date:       Order.next_rental_renewal_date(o.ordered_date.to_date, o.shipped_at&.to_date),
                      cancellable?:       o.cancellable_by_customer?,
                      destageable?:       o.can_be_destaged?,
                      destage_requested?: !!o.destage_date,
                      cc:                 o.credit_card,
                      furniture_subtotal: o.order_lines.product_lines.pluck(:base_price).sum.to_d,
                      is_frozen?:         o.frozen? || o.shipped?,
                      model:              o,
                  )
              end
              @soonest_destage_date = Order.soonest_destage_date
      
              # Get totals for each filter
              @filter_counts = {
                  open:             Order.count(filters[:required].merge(filters[:open])).to_i,
                  renting:          Order.count(filters[:required].merge(filters[:renting])).to_i,
                  void:             Order.count(filters[:required].merge(filters[:void])).to_i,
                  complete:         Order.count(filters[:required].merge(filters[:complete])).to_i,
                  pulled:           Order.count(filters[:required].merge(filters[:pulled])).to_i,
                  loaded:           Order.count(filters[:required].merge(filters[:loaded])).to_i,
                  destage:          Order.count(filters[:required].merge(filters[:destage])).to_i,
                  sales:            Order.count(filters[:required].merge(filters[:sales])).to_i,
              }

              
              if current_user&.location_rights == "ALL"
                  site_id = Site.all.pluck(:id)
              else  
                  site_id= Site.all(id: current_user&.location_rights&.split(','))&.pluck(:id)
              end
             
              @recently_returned = Product.recently_returned(amount: 7, site_id: site_id)
      end    
  end






           
  def get_cart
      binding.pry
      if current_user && current_user.cart
          
          @cart = ::SDN::Cart.new(current_user)
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

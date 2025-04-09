require 'sdn/order'
module Api
  module V1
    class OrdersController < ApplicationController
      skip_before_action :verify_authenticity_token
      def create
        begin
            $DB.transaction do
              if params[:order].present? && params[:address].present? && 
                 params[:order][:user_id].present? && params[:order][:site_id].present?
                address = Address.new(address_params)
                address.table_name = 'orders'
                address.save                
                @order = Order.new(order_params)
                @order.address = address if address.present?

                if @order.save
                  ta = TaxAuthority.create(active: 'Active', entry_mode: 'Auto', created_at: Time.now,
                                           created_by: @order.user_id, updated_at: Time.now,updated_by: @order.user_id,
                                           created_with: "CartReceipt", updated_with: "CartReceipt",tax_rate_source: 'Avalara',
                                           city_rate: 0.0000000, county_rate: 0.0000000, special_rate: 0.0000000,
                                           description: 'default',state_authority: 'default', state_rate: 0.0000000, total_rate: 0.0000000)
                  @order.update(tax_authority_id: ta.id) if ta.present?                         
                  render json: {status: 200, message: 'Order and shipping address created successfully.', order: @order }
                else
                  address.destroy if address.present?
                  render json: { status: 422, message: 'Order creation failed.', errors: @order.errors.full_messages }
                end
              else
                render json: { status: 400, message: 'Bad request.' }   
              end
            end  
        rescue ::SDN::Order::Exceptions::OrderError => error
          render json: { status: 400, message: 'Order creation failed.', errors: error.message } 
        rescue => error
          render json: { status: 400, message: 'Order creation failed.', errors: error.message }
        end
      end

      private

      def order_params
        params.require(:order).permit(:levels, :dwelling, :parking, :delivery_special_considerations, :user_id, :site_id, :type, :service, :status, :project_name, :ordered_date, :due_date)
      end

      def address_params
        params.require(:address).permit(:address1, :address2, :city, :state, :zipcode, :country_id, :phone, :mobile_phone, :latitude, :longitude)
      end
    end
  end
end

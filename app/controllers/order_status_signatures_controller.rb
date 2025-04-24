require 'sdn/order'
class OrderStatusSignaturesController < ApplicationController
    before_action :require_login

    def create
        errors = []
        if params[:signature_url]
            errors << 'Photo too large. Max size is 4 MB.' unless params[:signature_url].size <= 4.megabyte
            unless errors.any?
                new_filename = "#{current_user.username}_#{Time.zone.now.to_i}_#{params[:signature_url].original_filename}"
                s3_bucket = 'sdn-content'
                upload_success = $AWS.s3.upload(
                    params[:signature_url].tempfile,
                    bucket: s3_bucket,
                    as: new_filename,
                )
                if upload_success
                    file_url = $AWS.s3.public_url_for(new_filename, bucket: s3_bucket)
                else
                    errors << 'Error uploading photo.'
                end
            end
        end
        order_status_signature = OrderStatusSignature.new(notes: params[:notes], signature_url: file_url, 
                                                             order_status: params[:order_status], updated_by: current_user.id, 
                                                             order_id: params[:order_id], created_at: Time.now)
        ActiveRecord::Base.transaction do
            if order_status_signature.save
                order = Order.where(id: params[:order_id])&.first
                order.update(status: params[:order_status]) if order.present?
                previous_status = ""
                params[:product_ids]&.split(' ').each do |pp|
                    product_id, line_id = pp.split('-')
                    product_piece = ProductPiece.where(product_id: product_id, order_line_id: line_id)&.first
                    
                    order_line = OrderLine.where(id: line_id)&.first
                    product = product_piece.product
                    
                    previous_status = product_piece.status                     
                    if params[:order_status] == "Renting"

                        all_pieces = ProductPiece.where(product_id: product_id, order_line_id: order_line.id)
                        all_pieces.each do |product_piece|
                    
                            product_piece.status = params[pp]
                            if product_piece.save
                                ProductPieceLog.create(
                                    product_id: product_id,
                                    order_line_id: line_id,
                                    product_epc_id: product_piece.product_epc_id,
                                    epc_code: product_piece.epc_code,
                                    previous_status: previous_status,
                                    status:  params[pp],
                                    confirmed_at: Time.now,
                                    created_at: Time.now,
                                    added_by: current_user&.id
                                )    
                            end
                        end        
                    elsif params[:order_status] == "Complete"
                        
                        if order_line.type == "rent"
                            quantity = product.quantity
                            product.update(quantity: quantity + order_line.quantity)
                        end

                        all_pieces = ProductPiece.where(product_id: product_id, order_line_id: order_line.id)
                        all_pieces.each do |product_piece|
                            product_piece.status = order_line&.type == "rent" ? params[pp] : "Sold"
                            product_piece.order_line_id = 0
                            
                            if product_piece.save
                                ProductPieceLog.create(
                                    product_id: product_id,
                                    order_line_id: order_line.id,
                                    product_epc_id: product_piece.product_epc_id,
                                    epc_code: product_piece.epc_code,
                                    previous_status: previous_status,
                                    status: order_line&.type == "rent" ? params[pp] : "Sold",
                                    confirmed_at: Time.now,
                                    created_at: Time.now,
                                    added_by: current_user&.id
                                )
                            end 
                        end      
 
                    end       
                end if params[:product_ids].present?
                redirect_to account_order_path(order.id), notice: 'Order status updated.'
            else
                redirect_to account_order_path(order.id), error: 'There is something wrong.'
            end
        end       
    end    
end

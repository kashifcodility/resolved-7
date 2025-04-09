require 'sdn/card'
require 'sdn/order'

class RoomsController < ApplicationController
    before_action :require_login

    def index
      @rooms = Room.active_rooms_ordered_by_position(current_user&.id)
    end

    # New password form
    def new_room
        
    end

    def create
        current_position = Room.all(user_id: current_user&.id).map(&:position).max || 0
        room = current_user.rooms.new(name: params[:name], zone: 'NULL', 
                                  token: params[:name], position: current_position + 1)
        if room.save
            redirect_to "/rooms", notice: "Room created successfully."
        else
            render :new
        end   
    end
    
    def edit
        @room = Room.find(params[:id])
    end
    
    def update
        room = Room.find(params[:id])
        
        if room.update(name: params[:name])
            redirect_to "/rooms", notice: "Room updated successfully."
        else
            render :edit
        end
    end

    def destroy
      room = Room.find(params[:id])
      ol = OrderLine.first(room_id: room.id)
      if ol.blank?
        room.destroy
        redirect_to "/rooms", notice: "Room deleted successfully."
      else
        redirect_to "/rooms", notice: "Room associated with order line and can't be deleted."
      end    
    end    

    def sort
      params[:order].each_with_index do |id, index|
        room = Room.first(id: id)
        room.update(position: index + 1) if room.present?
      end
      head :ok  
    end
    
    

end

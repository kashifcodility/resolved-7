class DeliveryAppointmentsController < ApplicationController

  def index
    if current_user.type == "Employee"
      @delivery_appointments = DeliveryAppointment.all
    else
      @delivery_appointments = DeliveryAppointment.all(user_id: current_user.id)
    end
  end

  def new
  end

  def edit
    @delivery_appointment = DeliveryAppointment.find(params[:id])
  end

  def update
    @delivery_appointment = DeliveryAppointment.find(params[:id])
    params[:status] == "on" ? status = true : status = false
    if @delivery_appointment.update(schedule_date: params[:schedule_date],
                                   status: status, special_instructions: params[:special_instructions])
      redirect_to '/delivery_appointments', notice: 'Delivery appointment updated successfully.'
    else
      render :edit
    end
  end


  def create
    delivery_appointment = DeliveryAppointment.new(schedule_date: params[:schedule_date],
                                                   user_id: current_user.id, special_instructions: params[:special_instructions],
                                                   approx_budget: params[:approx_budget], client_name: params[:client_name],
                                                   contact_info: params[:contact_info], project_name: params[:project_name],
                                                   delivery: params[:delivery])
    if delivery_appointment.save
      redirect_to '/delivery_appointments', notice: 'Delivery appointment created successfully.'
    else
      render :new_delivery_appointment
    end
  end
end

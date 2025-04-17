require 'sidekiq-scheduler'

class OrderRecurringWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    orders = Order.all(:due_date.gte => 30.days.ago.beginning_of_day, :due_date.lte => 30.days.ago.end_of_day, status: "Renting")
    orders.each do |order| 
      sdn_user = order.user
      customer_id = IntuitAccount.create_quickbooks_customer(sdn_user)
      IntuitAccount.create_quickbooks_invoice(order.id, customer_id, true) if order.present? && customer_id.present?

      # generate stripe invoice too
      service = StripeInvoiceService.new(sdn_user, order) 
      invoice = service.create_invoice(true)  if order.present?
    end  unless orders.blank? 
  end
end
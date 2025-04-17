require 'sidekiq-scheduler'

class QboInvoiceWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default # Optional: Specify the queue

  def perform
    orders = Order.all(:due_date.gte => DateTime.now.beginning_of_day, :due_date.lte => DateTime.now.end_of_day)
    orders.each do |order| 
      sdn_user = order.user
      db_invoice = Invoice.first(order_id: order.id) 
      customer_id = IntuitAccount.create_quickbooks_customer(sdn_user) if db_invoice.blank? 
      IntuitAccount.create_quickbooks_invoice(order.id, customer_id, false) if order.present? && customer_id.present? && db_invoice.blank?  

      # generate stripe invoice too
      service = StripeInvoiceService.new(sdn_user, order) 
      invoice = service.create_invoice(false)  if order.present?
    end  unless orders.blank? 
  end
end


# class OrderQuery
#   include DataMapper::Resource

#   property :id, Serial
#   property :message, Text

#   property :is_employee, Boolean, default: false
#   property :is_customer, Boolean, default: false
#   property :image_url, String, length: 255
#   property :docs, Text
#   property :is_read, Boolean, default: false

#   property :order_id, Integer, index: true
#   property :user_id,  Integer, index: true
#   property :recipient_id,  Integer, index: true

#   belongs_to :order
#   belongs_to :user
# end


class OrderQuery < ApplicationRecord
  self.table_name = 'order_queries'

  validates :message, presence: true

  belongs_to :order
  belongs_to :user

  def is_employee?
    self.is_employee
  end

  def is_customer?
    self.is_customer
  end

  def is_read?
    self.is_read
  end
end

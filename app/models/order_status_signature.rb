# class OrderStatusSignature
#   include DataMapper::Resource

#   property :id, Serial
#   property :notes, Text

#   property :signature_url, String, length: 255
#   property :order_status, String, length: 255
#   property :created_at, DateTime
#   belongs_to :order
#   property :updated_by, Integer

# end


class OrderStatusSignature < ApplicationRecord
  self.table_name = 'order_status_signatures'

  validates :signature_url, length: { maximum: 255 }
  validates :order_status, length: { maximum: 255 }

  belongs_to :order

  # Additional validations or callbacks can be added here
end

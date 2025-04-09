# class PaymentType
#     include DataMapper::Resource

#     storage_names[:default] = "payment_type"

#     property :id, Serial

#     property :type, String, length: 32
#     property :description, String, length: 96

#     has 0..n, :payments, model: 'PaymentLog'
# end


class PaymentType < ApplicationRecord
    self.table_name = "payment_type"

    validates :type, length: { maximum: 32 }
    validates :description, length: { maximum: 96 }

    has_many :payments, class_name: 'PaymentLog'
end

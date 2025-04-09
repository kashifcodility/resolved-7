# class ServiceCategory
#     include DataMapper::Resource

#     storage_names[:default] = 'service_categories'

#     property :id, Serial

#     property :service_category, String, length: 50
#     property :active, String, length: 10, default: "Active"
#     property :suggested, Integer, default: 0, allow_nil: true
#     property :sequence, Integer, default: 2
# end


class ServiceCategory < ApplicationRecord
    # self.table_name = 'service_categories'

    validates :service_category, length: { maximum: 50 }
    validates :active, length: { maximum: 10 }, default: "Active"
    validates :suggested, numericality: { only_integer: true }, allow_nil: true, default: 0
    validates :sequence, numericality: { only_integer: true }, default: 2
end

# class ProductEditLog
#     include DataMapper::Resource

#     storage_names[:default] = "product_edit_log"
    
#     property :id, Serial

#     property :product_id, Integer, allow_nil: false
#     belongs_to :product
    
#     property :user_id, Integer, allow_nil: false
#     belongs_to :user

#     property :action, String, allow_nil: false
#     property :old_value, String, allow_nil: true, length: 255
#     property :new_value, String, allow_nil: false, length: 255
    
#     property :created_at, DateTime

# end


class ProductEditLog < ApplicationRecord
    belongs_to :product
    belongs_to :user

    validates :product_id, presence: true
    validates :user_id, presence: true
    validates :action, presence: true
    validates :new_value, presence: true, length: { maximum: 255 }
    validates :old_value, length: { maximum: 255 }
end

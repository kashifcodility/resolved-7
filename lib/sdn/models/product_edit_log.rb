class ProductEditLog
    include DataMapper::Resource

    storage_names[:default] = "product_edit_log"
    
    property :id, Serial

    property :product_id, Integer, allow_nil: false
    belongs_to :product
    
    property :user_id, Integer, allow_nil: false
    belongs_to :user

    property :action, String, allow_nil: false
    property :old_value, String, allow_nil: true, length: 255
    property :new_value, String, allow_nil: false, length: 255
    
    property :created_at, DateTime

end

# class OrderEditLog
#     include DataMapper::Resource

#     storage_names[:default] = "order_edit_log"
    
#     property :id, Serial

#     property :order_id, Integer, allow_nil: false
#     belongs_to :order
    
#     property :user_id, Integer, allow_nil: false
#     belongs_to :user

#     property :action, String, allow_nil: false
#     property :old_value, String, allow_nil: true, length: 255
#     property :new_value, String, allow_nil: false, length: 255

#     property :created_at, DateTime

class OrderEditLog < ApplicationRecord
    # Associations
    belongs_to :order
    belongs_to :user
  
    # Validations (optional)
    validates :order_id, presence: true
    validates :user_id, presence: true
    validates :action, presence: true
    validates :new_value, presence: true, length: { maximum: 255 }
    validates :old_value, length: { maximum: 255 }, allow_nil: true

    def self.add_product(order, product, user:)
        OrderEditLog.create(
            order_id:  order.id,
            user_id:   user.id,
            action:    'add_product',
            new_value: product.id,
        )
    end
    
    def self.create_before_save(order, user:)
        return true unless order.dirty_attributes.any?
        order.dirty_attributes.each do |new|
            old = order.original_attributes.find { |a| a[0].name == new[0].name }
            OrderEditLog.create(
                order_id:  order.id,
                user_id:   user.id,
                action:    "update_#{new[0].name.to_s}",
                old_value: old[1].to_s.truncate(255),
                new_value: new[1].to_s.truncate(255),
            )
        end
    end

    def self.search_user_action_values(query)
        return all() unless query
        return all(conditions: [ "CAST(user_id AS CHAR) LIKE '#{query.to_i}%'" ]) | 
               all(OrderEditLog.user.first_name.like => "%#{query}%") |
               all(OrderEditLog.user.last_name.like => "%#{query}%") |
               all(OrderEditLog.user.email.like => "%#{query}%") |
               all(:action.like => "%#{query}%") |
               all(:old_value.like => "%#{query}%") | 
               all(:new_value.like => "%#{query}%")               
    end
end

# class Room
#     include DataMapper::Resource

#     property :id, Serial

#     property :name, String, length: 64

#     property :zone, StringEnum['NULL','Bathroom','Bedroom','Dining Room',
#                                 'Extra Room','Kitchen','Living Room','Office','Outside']
    
#     property :token, String, length: 16

#     property :user_id, Integer, required: true, default: 0

#     property :position, Integer, required: true, default: 0

#     has n, :order_lines
#     belongs_to :user

#     def self.active_rooms_ordered_by_position(id)
#         all(user_id: id, order: [:position.asc]) # Orders by position in ascending order
#     end
# end

class Room < ApplicationRecord
    self.table_name = "rooms"
  
    validates :name, length: { maximum: 64 }
    
    enum zone: { 'NULL' => 'NULL', 'Bathroom' => 'Bathroom', 'Bedroom' => 'Bedroom', 'Dining Room' => 'Dining Room',
               'Extra Room' => 'Extra Room', 'Kitchen' => 'Kitchen', 'Living Room' => 'Living Room',
               'Office' => 'Office', 'Outside' => 'Outside' }

    validates :token, length: { maximum: 16 }
    
    validates :user_id, presence: true, numericality: { only_integer: true }
  
    has_many :order_lines
    belongs_to :user

    def self.active_rooms_ordered_by_position(user_id)
        where(user_id: user_id).order(position: :asc)
    end
      
end
  
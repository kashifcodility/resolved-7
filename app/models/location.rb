class Location < ApplicationRecord
    # Validations can be added as needed
    validates :location, length: { maximum: 30 }
    validates :warehouse_id, numericality: { only_integer: true }
    validates :active, length: { maximum: 15 }
end
  

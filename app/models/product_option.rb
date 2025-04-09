# Maps options and categories to a product
# class ProductOption
#     include ::DataMapper::Resource

#     storage_names[:default] = 'yuxi_products'

#     # property :id, Serial, key: true

#     belongs_to :product, key: true

#     # belongs_to :product
#     belongs_to :category
    

    
#     # these beow 4 lines open for import data only.belong_to lines will be commented for this purpose.
#     property :material_id, String
#     property :color_id, String
#     property :size_id, String
#     property :texture_id, String
#     property :fabric_id, String

class ProductOption < ApplicationRecord
    # Set the table name explicitly
    self.table_name = 'yuxi_products'
  
    # Associations
    belongs_to :product
    belongs_to :category
  
    # Fields for import data
    # material_id, color_id, size_id, texture_id, fabric_id
  
    # Validations (if needed)
    # validates :material_id, :color_id, :size_id, :texture_id, :fabric_id, presence: true
  



    def colors
        # Split the color_id string (e.g., "11,12,13") into an array of integers
        color_ids = self.color_id&.split(',')&.map(&:to_i)
    
        # Fetch and return associated Option objects for each color_id
        Option.where(id: color_ids)
    end

    def materials
        # Split the color_id string (e.g., "11,12,13") into an array of integers
        material_ids = self.material_id&.split(',')&.map(&:to_i)
    
        # Fetch and return associated Option objects for each color_id
        Option.where(id: material_ids)
    end

    def sizes
        # Split the color_id string (e.g., "11,12,13") into an array of integers
        size_ids = self.size_id&.split(',')&.map(&:to_i)
    
        # Fetch and return associated Option objects for each color_id
        Option.where(id: size_ids)
    end

    # belongs_to :material, 'Option', child_key: [ :material_id ], required: false, default: 0
    # belongs_to :color,    'Option', child_key: [ :color_id ],    required: false, default: 0
    # belongs_to :fabric,   'Option', child_key: [ :fabric_id ],   required: false, default: 0
    # belongs_to :texture,  'Option', child_key: [ :texture_id ],  required: false, default: 0
    # belongs_to :the_size, 'Option', child_key: [ :size_id ],     required: false, default: 0 # using `:size` broke shit... reserved?

    # property :is_premium,      Boolean, default: false
    # property :discount_rental, Boolean, default: false
    # property :sales_item,      Boolean, default: false
    # property :closeout,        Boolean, default: false

end

# Maps options and categories to a product
class ProductOption
    include ::DataMapper::Resource

    storage_names[:default] = 'yuxi_products'

    belongs_to :product, key: true
    belongs_to :category

    belongs_to :material, 'Option', child_key: [ :material_id ], required: false, default: 0
    belongs_to :color,    'Option', child_key: [ :color_id ],    required: false, default: 0
    belongs_to :fabric,   'Option', child_key: [ :fabric_id ],   required: false, default: 0
    belongs_to :texture,  'Option', child_key: [ :texture_id ],  required: false, default: 0
    belongs_to :the_size, 'Option', child_key: [ :size_id ],     required: false, default: 0 # using `:size` broke shit... reserved?

    property :is_premium,      Boolean, default: false
    property :discount_rental, Boolean, default: false
    property :sales_item,      Boolean, default: false
    property :closeout,        Boolean, default: false

end

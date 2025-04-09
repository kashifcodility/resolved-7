class Category
    include ::DataMapper::Resource

    storage_names[:default] = 'yuxi_categories'

    property :id, Serial

    property :name, String, length: 40

    property :parent_id, Integer, field: 'parentid', allow_nil: true
    belongs_to :parent, 'Category', child_key: [ :parent_id ]

    has 0..n, :children, 'Category', child_key: [ :parent_id ]

    # This is actually a tiny int
    property :display_order, Integer, field: 'order', default: 1

    has 0..n, :product_options

    has 1, :category_count
    def count(); self.category_count&.count; end

    # Count of all products in this category and all child categories
    def deep_product_count
        ProductOption.all(category_id: id_tree).count
    end

    # self.id + all children.id's
    def id_tree(model=self, ids=[])
        ids << model.id
        model.children.each { |child| id_tree(child, ids) }
        return ids
    end

    # NOTE: Doesn't account for nesting
    def self.root_categories_with_children
        Category.all(parent_id: nil, :children.not => nil, order: [ :display_order ])
    end
    
    def self.categories_with_products
        Category.all(id: ProductOption.all(fields: [ :category_id ], unique: true).pluck(:category_id), order: [ :display_order ])
    end

end

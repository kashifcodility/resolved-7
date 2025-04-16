class OrderLineDetail < ApplicationRecord
    self.table_name = "order_lines_detail"
    self.primary_key = "order_lines_id"  # Assuming you're keeping this as PK
  
    belongs_to :order_line, foreign_key: "order_lines_id"
  
    # Aliases for consistency if needed
    alias_attribute :order_line_id, :order_lines_id
    alias_attribute :ordered_at, :ordered
    alias_attribute :shipped_at, :shipped
    alias_attribute :returned_at, :returned
  
    def product
      order_line&.product
    end
  
    def returned?
      returned_at.present?
    end
end
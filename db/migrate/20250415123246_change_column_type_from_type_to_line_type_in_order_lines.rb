class ChangeColumnTypeFromTypeToLineTypeInOrderLines < ActiveRecord::Migration[7.2]
  def change
    rename_column :order_lines, :type, :line_type
  end
end

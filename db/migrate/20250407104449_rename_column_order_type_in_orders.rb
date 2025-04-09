class RenameColumnOrderTypeInOrders < ActiveRecord::Migration[7.2]
  def change
    rename_column :orders, :type, :order_type
  end
end

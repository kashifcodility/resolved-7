class RenameColumnChangedToIsChangedInOrders < ActiveRecord::Migration[7.2]
  def change
    rename_column :orders, :changed, :is_changed
  end
end

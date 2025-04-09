class RenameColumnTypeInAttributes < ActiveRecord::Migration[7.2]
  def change
    rename_column :attributes, :type, :attribute_type
  end
end

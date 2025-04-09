class RenameColumnTypeInUsers < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :type, :user_type
  end
end

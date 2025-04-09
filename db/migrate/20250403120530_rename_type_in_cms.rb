class RenameTypeInCms < ActiveRecord::Migration[7.2]
  def change
    # ALTER TABLE cms MODIFY updated_at DATETIME DEFAULT NULL;

    # update cms set created_at = '2024-06-11 21:44:26';  run above and this query before run migration using mysql shell.
    rename_column :cms, :type, :column_type
  end
end

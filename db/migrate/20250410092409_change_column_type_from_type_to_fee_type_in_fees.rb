class ChangeColumnTypeFromTypeToFeeTypeInFees < ActiveRecord::Migration[7.2]
  def change
    rename_column :fees, :type, :fee_type
  end
end

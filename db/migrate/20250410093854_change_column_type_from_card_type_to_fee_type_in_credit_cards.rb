class ChangeColumnTypeFromCardTypeToFeeTypeInCreditCards < ActiveRecord::Migration[7.2]
  def change
    rename_column :credit_cards, :type, :card_type
  end
end

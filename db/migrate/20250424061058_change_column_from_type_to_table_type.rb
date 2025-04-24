class ChangeColumnFromTypeToTableType < ActiveRecord::Migration[7.2]
  def change
    rename_column :sites, :type, :site_type
    rename_column :charge_account_charges, :type, :charge_account_charges_type
    rename_column :commission, :type, :commission_type
    rename_column :company_correspondence, :type, :company_correspondence_type
    rename_column :edit_log, :type, :edit_log_type
    rename_column :email_log, :type, :email_log_type
    rename_column :extra_fees, :type, :extra_fees_type
    rename_column :order_deposits, :type, :order_deposits_type
    rename_column :payment_type, :type, :payment_type_type
    rename_column :product_nontransient_dates, :type, :product_nontransient_dates_type
    rename_column :products_copy, :type, :products_copy_type
    rename_column :stat_customer, :type, :stat_customer_type
    rename_column :refund_log, :type, :refund_log_type
    rename_column :shipping_approval_codes, :type, :shipping_approval_codes_type
    rename_column :transactions, :type, :transactions_type

  end
end

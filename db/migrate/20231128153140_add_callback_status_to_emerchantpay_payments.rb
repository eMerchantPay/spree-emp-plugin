# 3DSv2 Callback Status field DB migration
class AddCallbackStatusToEmerchantpayPayments < ActiveRecord::Migration[6.1]

  def change
    add_column :emerchantpay_payments, :callback_status, :string
  end

end

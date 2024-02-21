# Add Emerchanptay Payments DB migration
class AddEmerchantpayPayments < ActiveRecord::Migration[6.1]

  def up # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    create_table 'emerchantpay_payments', if_not_exists: true do |t|
      t.string 'transaction_id', null: false
      t.string 'unique_id', limit: 512
      t.string 'reference_id', limit: 512
      t.string 'payment_method', null: false, limit: 128
      t.string 'terminal_token', null: false
      t.string 'status', limit: 64
      t.string 'order_id', limit: 128
      t.string 'payment_id', limit: 128
      t.string 'transaction_type'
      t.integer 'amount', null: false
      t.string 'currency', null: false
      t.string 'mode', null: false
      t.string 'message', limit: 512
      t.string 'technical_message', limit: 2048
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
      t.json 'request'
      t.json 'response'
      t.index %w(unique_id), name: 'idx_unique_id'
      t.index %w(transaction_id transaction_type), name: 'idx_unique_transaction_type', unique: true
      t.index %w(order_id payment_id), name: 'idx_order_payment_id'
    end
  end

  def down
    drop_table 'emerchantpay_payments'
  end

end

class AddCheckoutSource < ActiveRecord::Migration[6.1]

  def up # rubocop:disable Metrics/MethodLength
    create_table 'emerchantpay_checkout_sources', if_not_exists: true do |t|
      t.string 'consumer_id', limit: 256
      t.string 'consumer_email', limit: 512, index: true
      t.string 'name', limit: 64
      t.string 'payment_method_id', limit: 64
      t.string 'user_id', limit: 64
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
      t.datetime 'deleted_at', precision: 6
      t.jsonb 'public_metadata'
      t.jsonb 'private_metadata'
    end
  end

  def down
    drop_table 'emerchantpay_checkout_sources'
  end

end

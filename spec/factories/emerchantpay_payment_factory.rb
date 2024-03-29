FactoryBot.define do
  factory :emerchantpay_payment, class: 'SpreeEmerchantpayGenesis::Db::EmerchantpayPayment' do
    transaction_id { Faker::Internet.uuid }
    unique_id { Faker::Internet.uuid }
    reference_id { Faker::Internet.uuid }
    terminal_token { Faker::Internet.uuid }
    status { 'approved' }
    transaction_type { 'authorize3d' }
    mode { 'test' }
    response { { timestamp: DateTime.now } }
  end

  factory :emerchantpay_direct_payment,
          parent: :emerchantpay_payment,
          class: 'SpreeEmerchantpayGenesis::Db::EmerchantpayPayment' do
    payment_method { Spree::Gateway::EmerchantpayDirect }
  end

  factory :emerchantpay_checkout_payment,
          parent: :emerchantpay_payment,
          class: 'SpreeEmerchantpayGenesis::Db::EmerchantpayPayment' do
    payment_method { Spree::Gateway::EmerchantpayCheckout }
  end
end

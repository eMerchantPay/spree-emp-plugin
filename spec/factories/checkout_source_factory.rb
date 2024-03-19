FactoryBot.define do
  factory :emerchantpay_checkout_source, class: 'Spree::EmerchantpayCheckoutSource' do
    before(:create) do |object|
      object.payment_method = create(:emerchantpay_checkout_gateway)
    end

    consumer_id { '123456' }
    consumer_email { 'example@example.com' }
  end
end

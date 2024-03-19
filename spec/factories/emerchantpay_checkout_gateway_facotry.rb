FactoryBot.define do
  factory :emerchantpay_checkout_gateway, class: 'Spree::Gateway::EmerchantpayCheckout' do
    name { 'Emerchantpay Checkout' }

    # to write new specs please provide proper credentials
    # either here or in dummy secrets.yml file. Values will
    # be recorded on VCR, so they can be safely replaced with
    # placeholder afterwards
    transient do
      username { Rails.application.secrets.username || 'example_username' }
      password { Rails.application.secrets.password || 'example_password' }
      transaction_types { %w(authorize3d sale3d wechat post_finance trustly_sale) }
      challenge_indicator { 'preference' }
      test_mode { 'true' }
    end

    before(:create) do |gateway, evaluator|
      %w(username password transaction_types challenge_indicator test_mode).each do |preference|
        gateway.__send__ "preferred_#{preference}=", evaluator.__send__(preference)
      end

      if gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        gateway.stores << store
      end
    end
  end
end

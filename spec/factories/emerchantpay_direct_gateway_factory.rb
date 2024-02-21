FactoryBot.define do
  factory :emerchantpay_direct_gateway, class: 'Spree::Gateway::EmerchantpayDirect' do
    name { 'Emerchantpay Direct' }

    # to write new specs please provide proper credentials
    # either here or in dummy secrets.yml file. Values will
    # be recorded on VCR, so they can be safely replaced with
    # placeholder afterwards
    transient do
      username { Rails.application.secrets.username || 'example_username' }
      password { Rails.application.secrets.password || 'example_password' }
      token { Rails.application.secrets.token || 'example_token' }
      transaction_types { 'authorize3d' }
      challenge_indicator { 'mandate' }
      test_mode { 'true' }
    end

    before(:create) do |gateway, evaluator|
      %w(username password token transaction_types challenge_indicator test_mode).each do |preference|
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

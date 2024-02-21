FactoryBot.define do
  factory :credit_card_params, class: 'Spree::CreditCard' do
    verification_value { 123 }
    month { 12 }
    year { 1.year.from_now.year }
    number { '4111111111111111' }
    name { 'Spree Commerce' }
    cc_type { 'visa' }
  end

  factory :browser_params, parent: :credit_card_params, class: 'Hash' do
    accept_header { '*/*' }
    java_enabled { true }
    language { 'en-GB' }
    color_depth { '32' }
    screen_height { '400' }
    screen_width { '400' }
    time_zone_offset { '+0' }
    user_agent { Faker::Internet.user_agent }

    skip_create

    initialize_with { attributes }
  end

  factory :spree_credit_card, parent: :credit_card_params, class: 'Spree::CreditCard' do
    before(:create) do |object|
      object.payment_method = create(:emerchantpay_direct_gateway)
    end
  end

  factory :emerchantpay_credit_card_source, class: 'SpreeEmerchantpayGenesis::Sources::CreateCreditCard' do
    transient do
      payment_method
      user
    end

    initialize_with do
      SpreeEmerchantpayGenesis::Sources::CreateCreditCard.call(
        payment_method: payment_method,
        params: build(:browser_params),
        user: user
      ).value
    end
  end
end

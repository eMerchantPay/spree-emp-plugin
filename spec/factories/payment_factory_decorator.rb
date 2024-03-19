FactoryBot.define do
  factory :spree_payment, class: 'Spree::Payment' do
    amount { 0.99 }
    association(:order, factory: :order, currency: 'EUR')
    state { 'checkout' }
  end

  factory :fake_address, class: 'Hash' do
    name { 'John Smith' }
    address1 { Faker::Address.street_address }
    address2 { nil }
    city { 'City' }
    state { Faker::Address.state }
    zip { Faker::Address.zip_code }
    country { Faker::Address.country_code }
    phone { '88888888888' }

    skip_create

    initialize_with { attributes }
  end

  factory :gateway_options, class: 'Hash' do
    email { email }
    customer { email }
    customer_id { nil }
    ip { nil }
    order_id { "#{order_number}-#{payment_number}" }
    shipping { 0.99 }
    tax { 0.0 }
    subtotal { 0.99 }
    discount { 0.0 }
    currency { currency }

    skip_create

    initialize_with { attributes }
  end

  factory :gateway_options_with_address, parent: :gateway_options, class: 'Hash' do
    skip_create

    after(:build) do |object|
      object.merge! billing_address: build(:fake_address), shipping_address: build(:fake_address)
    end
  end
end

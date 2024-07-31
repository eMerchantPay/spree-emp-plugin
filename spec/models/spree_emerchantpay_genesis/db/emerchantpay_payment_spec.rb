RSpec.describe SpreeEmerchantpayGenesis::Db::EmerchantpayPayment do
  let(:emerchantpay_payment) do
    payment = described_class.new
    payment.transaction_id = Faker::Internet.uuid
    payment.payment_method = 'payment'
    payment.terminal_token = Faker::Internet.uuid
    payment.amount         = Faker::Number.positive
    payment.currency       = 'EUR'
    payment.mode           = 'test'
    payment.save!

    payment
  end

  it 'when formatted created_at' do
    expect(emerchantpay_payment.formatted_created_at).to be_a String
  end

  it 'when formatted updated_at' do
    expect(emerchantpay_payment.formatted_updated_at).to be_a String
  end
end

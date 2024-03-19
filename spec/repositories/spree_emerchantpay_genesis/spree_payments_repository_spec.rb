RSpec.describe SpreeEmerchantpayGenesis::SpreePaymentsRepository do
  it 'when find by number' do
    payment = create :spree_payment,
                     payment_method: create(:emerchantpay_direct_gateway),
                     source: create(:credit_card_params)

    expect(described_class.find_by_number(payment.number).number).to eq payment.number
  end
end

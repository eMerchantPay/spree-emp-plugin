RSpec.describe SpreeEmerchantpayGenesis::PaymentMethodHelper do
  it 'when fetch_method_type with invalid value' do
    expect(described_class.fetch_method_type('invalid')).to eq ''
  end
end

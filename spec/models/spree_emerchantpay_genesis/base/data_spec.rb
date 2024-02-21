RSpec.describe SpreeEmerchantpayGenesis::Base::Data do
  it 'when respond_to_missing' do
    expect(described_class.new.respond_to?(:missing)).to eq false
  end
end

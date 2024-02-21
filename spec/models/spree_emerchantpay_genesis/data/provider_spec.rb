RSpec.describe SpreeEmerchantpayGenesis::Data::Provider do
  let(:provider) { described_class.new }

  it 'when amount' do
    provider.total = nil

    expect(provider.amount).to eq nil
  end

  it 'when ip' do
    provider.ip = '10.10.10.10'

    expect(provider.ip).to eq '10.10.10.10'
  end
end

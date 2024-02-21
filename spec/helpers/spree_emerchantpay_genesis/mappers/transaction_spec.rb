RSpec.describe SpreeEmerchantpayGenesis::Mappers::Transaction do
  it 'with financial transaction type' do
    expect(described_class.for('authorize3d'))
      .to eq GenesisRuby::Api::Requests::Financial::Cards::Authorize3d
  end

  it 'with reference transaction type' do
    expect(described_class.for('capture')).to eq GenesisRuby::Api::Requests::Financial::Capture
  end
end

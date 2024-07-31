RSpec.describe SpreeEmerchantpayGenesis::TransactionHelper do
  it 'when generate response with default object' do
    expect(
      described_class.generate_spree_response(ActiveMerchant::Billing::Response.new(true, 'Success'))
    ).to be_a ActiveMerchant::Billing::Response
  end

  it 'when init reference request with invalid arguments' do
    expect { described_class.init_reference_req('capture', {}, 'invalid') }
      .to raise_error GenesisRuby::Error
  end
end

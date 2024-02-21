RSpec.describe SpreeEmerchantpayGenesis::ThreedsHelper do
  let(:shipping_address) { create(:ship_address, created_at: Date.current.last_year) }

  it 'when fetch_shipping_address_first_used with shipping_address' do
    expect(described_class.fetch_shipping_address_first_used(shipping_address))
      .to eq Date.current.last_year.strftime(SpreeEmerchantpayGenesis::ThreedsHelper::DATE_ISO_FORMAT)
  end

  it 'when fetch_class_indicator with lest than 30 days' do
    expect(described_class.fetch_class_indicator(
             'UpdateIndicators',
             Date.current.days_ago(2).strftime(SpreeEmerchantpayGenesis::ThreedsHelper::DATE_ISO_FORMAT)
           )).to eq 'less_than_30days'
  end

  it 'when fetch_class_indicator with more than 30 days and less than 60' do
    expect(described_class.fetch_class_indicator(
             'UpdateIndicators',
             Date.current.days_ago(33).strftime(SpreeEmerchantpayGenesis::ThreedsHelper::DATE_ISO_FORMAT)
           )).to eq '30_to_60_days'
  end

  it 'when fetch_class_indicator with more than than 60' do
    expect(described_class.fetch_class_indicator(
             'UpdateIndicators',
             Date.current.days_ago(66).strftime(SpreeEmerchantpayGenesis::ThreedsHelper::DATE_ISO_FORMAT)
           )).to eq 'more_than_60days'
  end
end

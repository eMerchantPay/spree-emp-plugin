RSpec.describe SpreeEmerchantpayGenesis::Data::User do
  let(:create_address) { create(:address) }
  let(:user) { described_class.new }

  it 'with bill_address_id' do
    address = create_address
    user.bill_address_id = address.id

    expect(user.billing_address).to be_kind_of Spree::Address
  end

  it 'with ship_address_id' do
    address = create_address
    user.ship_address_id = address.id

    expect(user.shipping_address).to be_kind_of Spree::Address
  end
end

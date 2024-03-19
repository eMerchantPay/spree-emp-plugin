RSpec.describe Spree::EmerchantpayCheckoutSource do
  let(:source) { described_class.new }
  let(:payment) do
    create :spree_payment,
           payment_method: create(:emerchantpay_checkout_gateway),
           source:         create(:emerchantpay_checkout_source)
  end

  it 'when actions' do
    expect(source.actions).to eq %w(capture void credit)
  end

  it 'when can_capture' do
    payment.pend

    expect(source.can_capture?(payment)).to eq true
  end

  it 'when can_void' do
    payment.complete

    expect(source.can_void?(payment)).to eq true
  end

  it 'when can_credit' do
    payment.complete

    expect(source.can_credit?(payment)).to eq true
  end
end

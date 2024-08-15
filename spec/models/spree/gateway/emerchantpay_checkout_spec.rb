# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Spree::Gateway::EmerchantpayCheckout, :vcr do
  let(:gateway) { create :emerchantpay_checkout_gateway, preferred_language: 'bg' }
  let(:source) { create :emerchantpay_checkout_source }
  let(:payment) { create :spree_payment, payment_method: gateway, source: source }
  let(:order) { OrderWalkthrough.up_to(:payment) }
  let(:gateway_options) do
    add_payment_to_order!
    build :gateway_options_with_address,
          email: order.email,
          currency: order.currency,
          order_number: order.number,
          payment_number: payment.number
  end
  let(:add_payment_to_order!) { order.payments << payment }
  let(:complete_order!) do
    add_payment_to_order!
    order.next! until order.completed?
  end

  describe 'when behaviour' do
    it 'when capture type with disabled auto capture' do
      expect(gateway.auto_capture?).to be false
    end

    it 'with provider' do
      expect(gateway.provider).to be_a SpreeEmerchantpayGenesis::GenesisProvider
    end

    it 'with proper source class' do
      expect(gateway.payment_source_class.name).to eq Spree::EmerchantpayCheckoutSource.name
    end

    it 'with source required' do
      expect(gateway.source_required?).to be true
    end

    it 'with method type' do
      expect(gateway.method_type).to eq 'emerchantpay_checkout'
    end

    it 'with source support' do
      expect(gateway.supports?(source)).to be true
    end

    it 'with language' do
      expect(gateway.preferred_language).to eq 'bg'
    end

    it 'with transaction_types' do
      expect(gateway.preferred_transaction_types)
        .to eq %w(authorize3d sale3d wechat post_finance trustly_sale)
    end

    it 'with mobile transaction_type' do
      gate = described_class.new

      expect(gate.preferred_transaction_types[:values])
        .to include('google_pay_sale', 'google_pay_authorize', 'apple_pay_sale', 'apple_pay_authorize', 'pay_pal_sale',
                    'pay_pal_authorize', 'pay_pal_express')
    end

    it 'without excluded transaction_type' do
      gate = described_class.new

      expect(gate.preferred_transaction_types[:values]).to_not include('google_pay', 'apple_pay', 'ppro', 'pay_pal')
    end

    it 'with bank_codes' do
      gate = described_class.new

      expect(gate.preferred_bank_codes[:values])
        .to eq %w(CPI BCT BLK SE PF SN IT BR BB WP BN PS BO PID)
    end
  end

  describe 'when authorize' do
    it 'with purchase call' do
      allow(gateway).to receive(:purchase)

      gateway.authorize(99, source, gateway_options)

      expect(gateway).to have_received(:purchase)
    end
  end

  describe 'when purchase with order' do
    describe 'when pending async payment' do
      it 'with proper order state' do
        complete_order!

        expect(order.state).to eq 'complete'
      end

      it 'with proper payment state' do
        complete_order!

        expect(order.payments.first.state).to eq 'processing'
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers

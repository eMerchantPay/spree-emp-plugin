# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Spree::Gateway::EmerchantpayDirect, :vcr do
  let(:gateway) { create :emerchantpay_direct_gateway }
  let(:source) { create :credit_card_params }
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

    it 'when sale type with enabled auto capture' do
      gateway = create :emerchantpay_direct_gateway, transaction_types: 'sale3d'

      expect(gateway.auto_capture?).to be true
    end

    it 'with provider' do
      expect(gateway.provider).to be_kind_of SpreeEmerchantpayGenesis::GenesisProvider
    end

    it 'with proper source class' do
      expect(gateway.payment_source_class).to be_kind_of Spree::CreditCard.class
    end

    it 'with source required' do
      expect(gateway.source_required?).to be true
    end

    it 'with method type' do
      expect(gateway.method_type).to eq 'emerchantpay_direct'
    end

    it 'with source support' do
      expect(gateway.supports?(source)).to be true
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
    describe 'when authorize payment' do
      it 'with proper order state' do
        complete_order!

        expect(order.state).to eq 'complete'
      end

      it 'with proper payment state' do
        complete_order!

        expect(order.payments.first.state).to eq 'pending'
      end
    end

    describe 'when sale payment' do
      let(:gateway) { create :emerchantpay_direct_gateway, transaction_types: 'sale3d' }

      it 'with proper order state' do

        complete_order!

        expect(order.state).to eq 'complete'
      end

      it 'with proper payment state' do
        complete_order!

        expect(order.payments.first.state).to eq 'completed'
      end
    end

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

  describe 'when gateway actions' do
    let(:amount_in_cents) { GenesisRuby::Utils::MoneyFormat.amount_to_exponent payment.amount.to_s, payment.currency }

    it 'with purchase' do
      expect(gateway.purchase(amount_in_cents, source, gateway_options).approved?).to be true
    end

    it 'with capture' do # rubocop:disable RSpec/ExampleLength
      transaction_id = 'sp-c6910-b099-48be-ae5e-87f8cac3f'
      create :emerchantpay_payment,
             transaction_id: transaction_id,
             unique_id:      '7e82b1d4eae5ab35c51fbaa68b23bcbd',
             payment_method: payment.payment_method.name,
             payment_id:     payment.number,
             order_id:       payment.order.number,
             amount:         amount_in_cents,
             currency:       payment.order.currency

      expect(gateway.capture(amount_in_cents, transaction_id, gateway_options).success?).to eq true
    end

    describe 'when refund' do
      let(:emerchantpay_payment) do
        create :spree_payment,
               payment_method: gateway,
               source: source,
               state: 'completed',
               order_id: payment.order.id
      end

      it 'with first level final transaction' do # rubocop:disable RSpec/ExampleLength
        transaction = create :emerchantpay_payment,
                             transaction_id:   'sp-d8d3d-380a-48ab-b136-dd894711b',
                             unique_id:        'ce67aa24ca6ac656684af4a302a6214d',
                             reference_id:     nil,
                             payment_method:   emerchantpay_payment.payment_method.name,
                             transaction_type: 'sale3d',
                             payment_id:       emerchantpay_payment.number,
                             order_id:         emerchantpay_payment.order.number,
                             amount:           amount_in_cents,
                             currency:         emerchantpay_payment.order.currency
        refund      = {
          originator: create(:refund, amount: emerchantpay_payment.amount, payment_id: emerchantpay_payment.id)
        }

        expect(gateway.credit(amount_in_cents, transaction.transaction_id, refund).success?).to eq true
      end

      it 'with second level final transaction' do # rubocop:disable RSpec/ExampleLength
        transaction = create :emerchantpay_payment,
                             transaction_id:   'sp-c6910-b099-48be-ae5e-87f8cac3f',
                             unique_id:        '7e82b1d4eae5ab35c51fbaa68b23bcbd',
                             reference_id:     'e8ead7e8645a70380c0759e87688881a',
                             payment_method:   emerchantpay_payment.payment_method.name,
                             transaction_type: 'authorize3d',
                             payment_id:       emerchantpay_payment.number,
                             order_id:         emerchantpay_payment.order.number,
                             amount:           amount_in_cents,
                             currency:         emerchantpay_payment.order.currency

        create :emerchantpay_payment,
               transaction_id:   'sp-d8d3d-380a-48ab-b136-dd894711b',
               unique_id:        'e8ead7e8645a70380c0759e87688881a',
               reference_id:     nil,
               payment_method:   emerchantpay_payment.payment_method.name,
               transaction_type: 'capture',
               payment_id:       emerchantpay_payment.number,
               order_id:         emerchantpay_payment.order.number,
               amount:           amount_in_cents,
               currency:         emerchantpay_payment.order.currency

        refund      = {
          originator: create(:refund, amount: emerchantpay_payment.amount, payment_id: emerchantpay_payment.id)
        }

        expect(gateway.credit(amount_in_cents, transaction.transaction_id, refund).success?).to eq true
      end
    end

    it 'with void' do # rubocop:disable RSpec/ExampleLength
      transaction = create :emerchantpay_payment,
                           transaction_id:   'sp-c6910-b099-48be-ae5e-87f8cac3f',
                           unique_id:        '7e82b1d4eae5ab35c51fbaa68b23bcbd',
                           reference_id:     nil,
                           payment_method:   payment.payment_method.name,
                           transaction_type: 'authorize3d',
                           payment_id:       payment.number,
                           order_id:         payment.order.number,
                           amount:           amount_in_cents,
                           currency:         payment.order.currency

      expect(gateway.void(transaction.transaction_id, gateway_options).success?).to be true
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers

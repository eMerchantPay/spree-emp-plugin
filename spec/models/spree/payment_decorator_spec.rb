RSpec.describe Spree::Payment do
  let(:spree_payment) do
    source = create(:spree_credit_card)
    create(:emerchantpay_direct_payment, payment_method: source.payment_method, source: source)
  end
  let(:create_emerchantpay_payment) do
    create(
      :emerchantpay_payment,
      payment_method: spree_payment.payment_method.name,
      payment_id:     spree_payment.number,
      order_id:       spree_payment.order.number,
      amount:         GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
        spree_payment.amount.to_s, spree_payment.currency
      ),
      currency:       spree_payment.order.currency
    )
  end

  describe 'when empty data' do
    it 'with proper response' do
      expect(spree_payment.emerchantpay_payments).to be_empty
    end
  end

  describe 'when data' do
    it 'when emerchantpay_payments with proper response' do
      create_emerchantpay_payment

      expect(spree_payment.emerchantpay_payments).to be_kind_of ActiveRecord::Relation
    end

    it 'when emerchantpay_payments with proper data' do
      emerchantpay_payment = create_emerchantpay_payment

      expect(spree_payment.emerchantpay_payments.first.transaction_id).to eq emerchantpay_payment.transaction_id
    end
  end
end

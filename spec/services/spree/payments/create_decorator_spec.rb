RSpec.describe Spree::Payments::Create do
  let(:order) { create(:order) }
  let(:payment_method) { create(:emerchantpay_direct_gateway) }
  let(:source) { create(:credit_card, user_id: order.user.id) }
  let(:params) do
    {
      payment_method_id: payment_method.id,
      source_id:         source.id,
      source_attributes: {
        name:               'John Smith',
        number:             '4200000000000000',
        month:              1,
        year:               2040,
        verification_value: '123',
        last_digits:        '0000'
      }
    }
  end
  let(:create_service) do
    described_class.call(
      order:  order,
      params: params
    )
  end

  before do
    allow(order).to receive_messages available_payment_methods: [payment_method]
  end

  describe 'when invalid source' do
    let(:create_service) do
      described_class.call(
        order: order,
        params: {
          payment_method_id: payment_method.id,
          source_id:         999_999
        }
      )
    end

    it 'with invalid source' do
      expect(create_service.error).to be_a Spree::ServiceModule::ResultError
    end
  end

  it 'with source from database' do
    expect(create_service).to be_a Spree::ServiceModule::Result
  end

  it 'with emerchantpay source' do
    params.delete :source_id

    expect(create_service.success).to be true
  end

  describe 'when default source' do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:spree_payment_method) { create(:credit_card_payment_method) }

    before do
      allow(order).to receive_messages available_payment_methods: [spree_payment_method]
    end

    it 'with default source' do
      params.delete :source_id
      params[:payment_method_id]                               = spree_payment_method.id
      params[:source_attributes][:gateway_payment_profile_id]  = 'card_1JqvNB2eZvKYlo2C5OlqLV7S'

      expect(create_service.success).to be true
    end
  end
end

RSpec.describe Spree::Api::V2::Storefront::EmerchantpayNotificationController, :vcr, type: :controller do
  describe 'when invalid request' do
    describe 'when missing param' do
      it 'with proper response body' do
        post :index

        expect(response.body).to_not be_empty
      end

      it 'with proper response code' do
        post :index

        expect(response).to have_http_status :bad_request
      end
    end

    describe 'when invalid params' do
      let(:params) { { unique_id: 'invalid', signature: 'invalid' } }

      it 'with proper response body' do
        post :index, params: params

        expect(response.body).to_not be_empty
      end

      it 'with proper response code' do
        post :index, params: params

        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe 'when valid request' do
    let(:params) do
      {
        unique_id: '846b2298647e3b3f7b0067a818113eb1',
        signature: '5f10e44d3789e6bf8e51f06d86a951db24c524cb'
      }
    end
    let(:payment) do
      create :emerchantpay_direct_payment,
             payment_method: create(:emerchantpay_direct_gateway),
             source: create(:credit_card_params)
    end
    let(:order) do
      order = OrderWalkthrough.up_to(:complete)

      order.payments << payment

      order
    end
    let(:create_payment) do
      create :emerchantpay_payment,
             unique_id:      params[:unique_id],
             payment_method: 'emerchantpay_direct',
             status:         'pending_async',
             amount:         11_000,
             currency:       'EUR',
             order_id:       order.number,
             payment_id:     payment.number
    end

    it 'with proper response body' do # rubocop:disable RSpec/ExampleLength
      if Rails.application.secrets.password
        skip 'Skipped: Secrets file is used. Callback signature is generated with default password.'
      end

      create_payment
      post :index, params: params

      expect(response.body).to eq "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<notification_echo>\n" \
                                    "  <unique_id>846b2298647e3b3f7b0067a818113eb1</unique_id>\n</notification_echo>\n"
    end

    it 'with proper response code' do # rubocop:disable RSpec/ExampleLength
      if Rails.application.secrets.password
        skip 'Skipped: Secrets file is used. Callback signature is generated with default password.'
      end

      create_payment
      post :index, params: params

      expect(response).to have_http_status :ok
    end

    it 'with error exception' do # rubocop:disable RSpec/ExampleLength
      if Rails.application.secrets.password
        skip 'Skipped: Secrets file is used. Callback signature is generated with default password.'
      end

      create_payment
      post :index, params: params

      expect(response.body).to eq 'Spree notification handling exited with: {:status=>"error", :code=>"110", ' \
        ':message=>"401 Unauthorized: Invalid Authentication!", :technical_message=>"Invalid Authentication"}'
    end
  end
end

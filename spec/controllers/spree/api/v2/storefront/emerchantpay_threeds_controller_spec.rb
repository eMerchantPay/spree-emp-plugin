RSpec.describe Spree::Api::V2::Storefront::EmerchantpayThreedsController, :vcr, type: :controller do

  describe 'when invalid params' do
    describe 'when callback_handler' do
      it 'with proper response body with missing unique_id' do
        post :callback_handler

        expect(response.body).to eq '{"error":"param is missing or the value is empty: unique_id"}'
      end

      it 'with proper response code with missing unique_id' do
        post :callback_handler

        expect(response).to have_http_status :bad_request
      end

      it 'with proper response body with invalid payment' do
        post :callback_handler, params: { unique_id: 'invalid', signature: 'invalid' }

        expect(response.body).to eq '{"error":"Given request is invalid!"}'
      end
    end

    describe 'when callback_status' do
      let(:params) { { unique_id: 'invalid' } }

      it 'with proper response body with invalid unique_id' do
        get :callback_status, params: params

        expect(response.body).to eq '{"error":"Given request is invalid!"}'
      end

      it 'with proper response code with invalid unique_id' do
        get :callback_status, params: params

        expect(response).to have_http_status :unprocessable_entity
      end
    end

    describe 'when method_continue' do
      let(:params) { { unique_id: 'invalid', signature: 'invalid' } }

      it 'with proper response body with invalid params' do
        post :method_continue, params: params

        expect(response.body).to eq '{"error":"Given request is invalid!"}'
      end

      it 'with proper response status with invalid params' do
        post :method_continue, params: params

        expect(response).to have_http_status :unprocessable_entity
      end

      it 'with proper response code with missing params' do
        params.delete(:unique_id)

        post :method_continue, params: params

        expect(response.body).to eq '{"error":"param is missing or the value is empty: unique_id"}'
      end
    end
  end

  describe 'when valid params' do
    let(:payment) do
      create :spree_payment,
             payment_method: create(:emerchantpay_direct_gateway),
             source: create(:credit_card_params)
    end
    let(:emerchantpay_payment) do
      create :emerchantpay_direct_payment,
             amount:         99,
             currency:       'EUR',
             order_id:       payment.order.number,
             payment_id:     payment.number
    end

    describe 'when callback_handler' do
      let(:params) do
        {
          unique_id:             emerchantpay_payment.unique_id,
          threeds_method_status: 'completed',
          signature:             Digest::SHA512.hexdigest(
            "#{emerchantpay_payment.unique_id}completed#{payment.payment_method.preferences[:password]}"
          )
        }
      end

      it 'with proper response body' do
        post :callback_handler, params: params

        expect(response.body).to eq({ status: params[:threeds_method_status] }.to_json)
      end

      it 'with callback_status update' do # rubocop:disable RSpec/MultipleExpectations
        expect(emerchantpay_payment.reload.callback_status).to be nil

        post :callback_handler, params: params

        expect(emerchantpay_payment.reload.callback_status).to eq 'completed'
      end

      it 'with invalid signature' do
        params[:threeds_method_status] = 'invalid'

        post :callback_handler, params: params

        expect(response.body).to eq({ status: '' }.to_json)
      end
    end

    describe 'when callback_status' do
      let(:update_callback_status) do
        emerchantpay_payment.callback_status = 'updated_status'
        emerchantpay_payment.save!
      end

      it 'without updated callback_status' do
        get :callback_status, params: { unique_id: emerchantpay_payment.unique_id }

        expect(response.body).to eq '{"status":""}'
      end

      it 'with updated callback_status' do
        update_callback_status

        get :callback_status, params: { unique_id: emerchantpay_payment.unique_id }

        expect(response.body).to eq({ status: 'updated_status' }.to_json)
      end
    end

    describe 'when method_continue' do
      let(:emerchantpay_pending_payment) do
        create :emerchantpay_direct_payment,
               transaction_id:   'sp-8f095-212d-41f3-8c2c-5da0b1365',
               unique_id:        '162d90bf750a62392b12a88010426ccd',
               reference_id:     nil,
               terminal_token:   payment.payment_method.preferences[:token],
               status:           'pending_async',
               payment_id:       payment.number,
               order_id:         payment.order.number,
               amount:           11_000,
               currency:         payment.order.currency,
               response:         {
                 transaction_type:            'authorize3d',
                 status:                      'pending_async',
                 unique_id:                   '162d90bf750a62392b12a88010426ccd',
                 transaction_id:              'sp-8f095-212d-41f3-8c2c-5da0b1365',
                 consumer_id:                 '156794',
                 technical_message:           'TESTMODE: No real money will be transferred!',
                 message:                     'TESTMODE: No real money will be transferred!',
                 threeds_method_url:          'https://staging.gate.emerchantpay.net/threeds/threeds_method',
                 threeds_method_continue_url: 'https://staging.gate.emerchantpay.net/threeds/threeds_method/' \
                   '162d90bf750a62392b12a88010426ccd',
                 mode:                        'test',
                 timestamp:                   '2024-02-06T16:10:19+00:00',
                 descriptor:                  'test',
                 amount:                      '110.00',
                 currency:                    'EUR',
                 sent_to_acquirer:            'false'
               }
      end

      it 'with redirect failure URL with error' do # rubocop:disable RSpec/ExampleLength
        post :method_continue, params: {
          unique_id: emerchantpay_payment.unique_id,
          signature: GenesisRuby::Utils::Threeds::V2.generate_signature(
            unique_id:         emerchantpay_payment.unique_id,
            amount:            emerchantpay_payment.amount,
            timestamp:         emerchantpay_payment.zulu_response_timestamp,
            merchant_password: payment.payment_method.preferences[:password]
          )
        }

        expect(response.body)
          .to(eq({
            status:       'OK',
            redirect_url: "http://localhost:4000/checkout/payment?order_number=#{payment.order.number}"
          }.to_json))
      end

      it 'with proper method_continue request with pending payment' do # rubocop:disable RSpec/ExampleLength
        post :method_continue, params: {
          unique_id: emerchantpay_pending_payment.unique_id,
          signature: GenesisRuby::Utils::Threeds::V2.generate_signature(
            unique_id:         emerchantpay_pending_payment.unique_id,
            amount:            emerchantpay_pending_payment.amount,
            timestamp:         emerchantpay_pending_payment.zulu_response_timestamp,
            merchant_password: payment.payment_method.preferences[:password]
          )
        }

        expect(response.body).to eq({ status: 'OK', redirect_url: 'https://staging.gate.emerchantpay.net/threeds/' \
          'authentication/162d90bf750a62392b12a88010426ccd' }.to_json)
      end

      it 'with proper method_continue request with approved payment' do # rubocop:disable RSpec/ExampleLength
        post :method_continue, params: {
          unique_id: emerchantpay_pending_payment.unique_id,
          signature: GenesisRuby::Utils::Threeds::V2.generate_signature(
            unique_id:         emerchantpay_pending_payment.unique_id,
            amount:            emerchantpay_pending_payment.amount,
            timestamp:         emerchantpay_pending_payment.zulu_response_timestamp,
            merchant_password: payment.payment_method.preferences[:password]
          )
        }

        expect(response.body)
          .to eq({ status: 'OK', redirect_url: "http://localhost:4000/orders/#{payment.order.number}" }.to_json)
      end

      it 'with proper method_continue request with error payment' do # rubocop:disable RSpec/ExampleLength
        post :method_continue, params: {
          unique_id: emerchantpay_pending_payment.unique_id,
          signature: GenesisRuby::Utils::Threeds::V2.generate_signature(
            unique_id:         emerchantpay_pending_payment.unique_id,
            amount:            emerchantpay_pending_payment.amount,
            timestamp:         emerchantpay_pending_payment.zulu_response_timestamp,
            merchant_password: payment.payment_method.preferences[:password]
          )
        }

        expect(response.body).to eq({
          status:       'OK',
          redirect_url: "http://localhost:4000/checkout/payment?order_number=#{payment.order.number}"
        }.to_json)
      end
    end
  end
end

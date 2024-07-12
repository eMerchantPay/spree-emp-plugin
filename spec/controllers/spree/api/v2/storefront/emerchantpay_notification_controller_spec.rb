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
    describe 'when processing notification' do
      let(:params) do
        {
          unique_id: '846b2298647e3b3f7b0067a818113eb1',
          signature: '5f10e44d3789e6bf8e51f06d86a951db24c524cb'
        }
      end
      let(:payment) do
        create :spree_payment,
               payment_method: create(:emerchantpay_direct_gateway),
               source: create(:credit_card_params)
      end
      let(:order) do
        order = OrderWalkthrough.up_to(:complete)

        order.payments << payment

        order
      end
      let(:create_payment) do
        create :emerchantpay_direct_payment,
               unique_id:      params[:unique_id],
               status:         'pending_async',
               amount:         11_000,
               currency:       'EUR',
               order_id:       order.number,
               payment_id:     payment.number
      end

      it 'with proper response body' do # rubocop:disable RSpec/ExampleLength
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Callback signature is generated with default password.'
        end

        create_payment
        post :index, params: params

        expect(response.body).to eq "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<notification_echo>\n" \
                                    "  <unique_id>846b2298647e3b3f7b0067a818113eb1</unique_id>\n</notification_echo>\n"
      end

      it 'with proper response code' do # rubocop:disable RSpec/ExampleLength
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Callback signature is generated with default password.'
        end

        create_payment
        post :index, params: params

        expect(response).to have_http_status :ok
      end

      it 'with error exception' do # rubocop:disable RSpec/ExampleLength
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Callback signature is generated with default password.'
        end

        create_payment
        post :index, params: params

        expect(response.body).to eq 'Spree notification handling exited with: {:status=>"error", :code=>"110", ' \
        ':message=>"401 Unauthorized: Invalid Authentication!", :technical_message=>"Invalid Authentication"}'
      end
    end

    describe 'when wpf notification' do
      let(:params) do
        {
          wpf_unique_id: '9aed8de9319c4c3806a9d1614797f853',
          signature:     'ff9f1a63dbd5263194cfcdf33062e653073c68c7'
        }
      end
      let(:payment) do
        create :spree_payment,
               payment_method: create(:emerchantpay_checkout_gateway),
               source: create(:emerchantpay_checkout_source)
      end
      let(:order) do
        order = OrderWalkthrough.up_to(:complete)

        order.payments << payment

        order
      end
      let(:create_payment) do
        create :emerchantpay_checkout_payment,
               unique_id:  params[:wpf_unique_id],
               status:     'new',
               amount:     11_000,
               currency:   'EUR',
               order_id:   order.number,
               payment_id: payment.number
      end

      it 'with proper response body' do # rubocop:disable RSpec/ExampleLength
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Callback signature is generated with default password.'
        end

        create_payment
        post :index, params: params

        expect(response.body).to eq "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<notification_echo>\n" \
                                    "  <wpf_unique_id>9aed8de9319c4c3806a9d1614797f853</wpf_unique_id>\n"\
                                    "</notification_echo>\n"
      end

      it 'with reference reconciliation' do # rubocop:disable RSpec/ExampleLength
        # Checkout Method with the processing unique_id
        create :emerchantpay_checkout_payment,
               unique_id:  'eafae2b35722a68ed9e4522ace7d720b',
               status:     'approved',
               amount:     11_000,
               currency:   'EUR',
               order_id:   order.number,
               payment_id: payment.number

        post :index, params: { wpf_unique_id:                 'ae1d51e6dcaae88635bb54b2aaa3257a',
                               signature:                     'd80593dfdb3959842fd028f74ccd356a5b124c65',
                               payment_transaction_unique_id: 'eafae2b35722a68ed9e4522ace7d720b' }

        expect(response.body).to eq "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<notification_echo>\n" \
                                    "  <wpf_unique_id>ae1d51e6dcaae88635bb54b2aaa3257a</wpf_unique_id>\n"\
                                    "</notification_echo>\n"
      end

      describe 'when authorized mobile payment' do # rubocop:disable RSpec/NestedGroups
        let(:payment) do
          create :spree_payment,
                 payment_method: create(:emerchantpay_checkout_gateway, transaction_types: %w(google_pay_authorize)),
                 source: create(:emerchantpay_checkout_source)
        end

        it 'with proper response' do
          create_payment

          post :index, params: params

          expect(response.body).to eq "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<notification_echo>\n" \
                                      "  <wpf_unique_id>9aed8de9319c4c3806a9d1614797f853</wpf_unique_id>\n"\
                                      "</notification_echo>\n"
        end

        it 'with proper payment status' do
          create_payment

          post :index, params: params

          expect(payment.reload.state).to eq 'pending'
        end
      end

      describe 'when sale mobile payment' do # rubocop:disable RSpec/NestedGroups
        let(:payment) do
          create :spree_payment,
                 payment_method: create(:emerchantpay_checkout_gateway, transaction_types: %w(apple_pay_sale)),
                 source: create(:emerchantpay_checkout_source)
        end

        it 'with proper response' do
          create_payment

          post :index, params: params

          expect(response.body).to eq "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<notification_echo>\n" \
                                      "  <wpf_unique_id>9aed8de9319c4c3806a9d1614797f853</wpf_unique_id>\n"\
                                      "</notification_echo>\n"
        end

        it 'with proper payment status' do
          create_payment

          post :index, params: params

          expect(payment.reload.state).to eq 'completed'
        end
      end

      describe 'when express mobile payment' do # rubocop:disable RSpec/NestedGroups
        let(:payment) do
          create :spree_payment,
                 payment_method: create(:emerchantpay_checkout_gateway, transaction_types: %w(pay_pal_express)),
                 source: create(:emerchantpay_checkout_source)
        end

        it 'with proper response' do
          create_payment

          post :index, params: params

          expect(response.body).to eq "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<notification_echo>\n" \
                                      "  <wpf_unique_id>9aed8de9319c4c3806a9d1614797f853</wpf_unique_id>\n"\
                                      "</notification_echo>\n"
        end

        it 'with proper payment status' do
          create_payment

          post :index, params: params

          expect(payment.reload.state).to eq 'completed'
        end
      end
    end
  end
end

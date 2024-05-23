RSpec.describe Spree::CheckoutController, :vcr, type: :controller do
  let(:user) { create :user }
  let(:order) { OrderWalkthrough.up_to :payment }

  include Devise::Test::ControllerHelpers

  before do
    allow(controller).to receive_messages try_spree_current_user: user
    allow(controller).to receive_messages spree_current_user: user
    allow(controller).to receive_messages current_order: order
    allow(controller).to receive_messages spree: Spree::Core::Engine.routes.url_helpers
  end

  describe 'when create_payment' do
    describe 'when emerchantpay checkout' do
      let(:gateway) { create :emerchantpay_checkout_gateway }
      let(:params) { { state: 'payment', order: { payments_attributes: [{ payment_method_id: gateway.id }] } } }

      it 'with successful response' do
        post :update, params: params

        expect(response)
          .to redirect_to 'https://staging.wpf.emerchantpay.net/en/v2/payment/9aed8de9319c4c3806a9d1614797f853'
      end

      it 'with unsuccessful response' do
        post :update, params: params

        # Uses Rails Storefront error page
        expect(response).to redirect_to 'http://test.host/checkout/payment'
      end
    end

    describe 'when emerchantpay direct' do
      let(:gateway) { create :emerchantpay_direct_gateway }
      let(:params) do
        params = {
          state:          'payment',
          order:          {
            payments_attributes: [{ payment_method_id: gateway.id }]
          },
          payment_source: {}
        }

        params[:payment_source][gateway.id.to_s.to_sym] = {
          name:               'John Smith',
          number:             '4938730000000001',
          expiry:             '12 / 25',
          verification_value: '123',
          cc_type:            '',
          accept_header:      '*/*',
          java_enabled:       'false',
          language:           'en-GB',
          color_depth:        '24',
          screen_height:      '1080',
          screen_width:       '1920',
          time_zone_offset:   '-180',
          user_agent:         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)' \
                              'Chrome/124.0.0.0 Safari/537.36'
        }

        params
      end

      it 'with successful response' do
        post :update, params: params

        expect(response).to redirect_to 'http://127.0.0.1:4000/emerchantpay_threeds/e6f86c7ca3b665e29f6d6c6eeb927788/' \
                                         '4ac9f028afcd081bad7574daf12843fd'
      end

      it 'with unsuccessful response' do
        post :update, params: params

        # Uses Rails Storefront error page
        expect(response).to redirect_to 'http://test.host/checkout/payment'
      end
    end

    describe 'when default logic' do
      let(:gateway) { create :check_payment_method }
      let(:params) { { state: 'payment', order: { payments_attributes: [{ payment_method_id: gateway.id }] } } }

      it 'with success response' do
        post :update, params: params

        expect(response).to redirect_to "http://test.host/orders/#{order.number}"
      end

      it 'with invalid params' do
        post :update, params: { state: 'payment' }

        expect(response).to redirect_to 'http://test.host/checkout/payment'
      end

      it 'with clean redirect' do
        expect { post :update, params: { state: 'payment' } }.to_not raise_error
      end

      it 'with error result' do
        allow(controller).to receive_messages default_payment_processing: nil

        post :update, params: params

        expect(response).to have_http_status :unprocessable_entity
      end

    end
  end

end

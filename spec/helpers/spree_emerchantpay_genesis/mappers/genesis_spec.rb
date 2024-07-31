# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe SpreeEmerchantpayGenesis::Mappers::Genesis do
  let(:source) { create(:spree_credit_card) }
  let(:spree_payment) do
    create :spree_payment,
           payment_method: source.payment_method,
           source: source
  end
  let(:options) { described_class.for_urls! spree_payment.payment_method.preferences, spree_payment.order.number }
  let(:mapped_order_with_address) do
    SpreeEmerchantpayGenesis::Mappers::Order.for(
      SpreeEmerchantpayGenesis::Mappers::Order.prepare_data(
        spree_payment.order,
        spree_payment.order.user,
        build(
          :gateway_options_with_address,
          email: spree_payment.order.email,
          currency: spree_payment.order.currency,
          order_number: spree_payment.order.number,
          payment_number: spree_payment.number
        )
      )
    )
  end
  let(:emerchantpay_source) do
    build(
      :emerchantpay_credit_card_source,
      payment_method: spree_payment.payment_method,
      user: spree_payment.order.user
    )
  end
  let(:payment) do
    described_class.for_payment(gate_request, mapped_order_with_address, emerchantpay_source, options).context
  end
  let(:gate_request) { build :genesis_authorize3d }
  let(:create_emerchantpay_payment) do
    create :emerchantpay_payment,
           transaction_id: '123456',
           payment_method: spree_payment.payment_method.name,
           payment_id:     spree_payment.number,
           order_id:       spree_payment.order.number,
           amount:         GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
             spree_payment.amount.to_s, spree_payment.currency
           ),
           currency:       spree_payment.order.currency
  end

  describe 'when config' do
    let(:config) { described_class.for_config(spree_payment.payment_method.preferences).context }

    it 'with proper type' do
      expect(config).to be_a GenesisRuby::Configuration
    end

    it 'with proper endpoint' do
      expect(config.endpoint).to eq 'emerchantpay.net'
    end

    it 'with proper environment' do
      expect(config.environment).to eq 'sandbox'
    end

    describe 'when production' do
      let(:config) do
        described_class.for_config(
          create(:emerchantpay_direct_gateway, preferred_test_mode: 'false').preferences
        ).context
      end

      it 'with proper environment' do
        expect(config.environment).to eq 'production'
      end
    end
  end

  describe 'when payment without order' do
    it 'with proper response' do
      expect(payment).to be_a GenesisRuby::Api::Requests::Financial::Cards::Authorize3d
    end

    describe 'with missing data' do
      let(:mapped_order) do
        SpreeEmerchantpayGenesis::Mappers::Order.for(
          SpreeEmerchantpayGenesis::Mappers::Order.prepare_data(
            spree_payment.order,
            spree_payment.order.user,
            build(
              :gateway_options,
              email: spree_payment.order.email,
              currency: spree_payment.order.currency,
              order_number: spree_payment.order.number,
              payment_number: spree_payment.number
            )
          )
        )
      end
      let(:payment) { described_class.for_payment(gate_request, mapped_order, emerchantpay_source, options).context }

      it 'without billing_address' do
        expect(payment.billing_first_name).to be_nil
      end

      it 'without shipping_address' do
        expect(payment.shipping_first_name).to be_nil
      end
    end

    describe 'with complete data' do
      it 'with transaction_id' do
        expect(payment.transaction_id).to_not be_nil || be_empty
      end

      it 'with amount' do
        expect(payment.amount).to eq '0.0'
      end

      it 'with currency' do
        expect(payment.currency).to eq 'EUR'
      end

      it 'with usage' do
        expect(payment.usage).to eq 'Electronic transaction via Spree eCommerce platform'
      end

      it 'with customer_email' do
        expect(payment.customer_email).to eq spree_payment.order.email
      end

      it 'with customer_phone' do
        expect(payment.customer_phone).to_not be_nil || be_empty
      end

      it 'with remote_ip' do
        expect(payment.remote_ip).to eq '127.0.0.1'
      end

      it 'with billing_first_name' do
        expect(payment.billing_first_name).to eq 'John'
      end

      it 'with billing_last_name' do
        expect(payment.billing_last_name).to eq 'Smith'
      end

      it 'with shipping_first_name' do
        expect(payment.shipping_first_name).to eq 'John'
      end

      it 'with shipping_last_name' do
        expect(payment.shipping_last_name).to eq 'Smith'
      end

      it 'with card holder' do
        expect(payment.card_holder).to eq 'Spree Commerce'
      end

      it 'with card number' do
        expect(payment.card_number).to eq '4111111111111111'
      end

      it 'with card expiration_month' do
        expect(payment.expiration_month).to eq 12
      end

      it 'with expiration_year' do
        expect(payment.expiration_year).to eq 1.year.from_now.year
      end

      it 'with cvv' do
        expect(payment.cvv).to eq '123'
      end

      it 'with notification_url' do
        expect(payment.notification_url).to eq 'http://127.0.0.1:4000/api/v2/storefront/emerchantpay_notification'
      end

      it 'with return_success_url' do
        expect(payment.return_success_url).to eq "http://localhost:4000/orders/#{spree_payment.order.number}"
      end

      it 'with return_failure_url' do
        expect(payment.return_failure_url)
          .to eq "http://localhost:4000/checkout/payment?order_number=#{spree_payment.order.number}"
      end

      it 'with purchase threeds_v2_purchase_category' do
        expect(payment.threeds_v2_purchase_category).to eq 'goods'
      end

      it 'with threeds_v2_method_callback_url' do
        expect(payment.threeds_v2_method_callback_url)
          .to eq 'http://127.0.0.1:4000/api/v2/storefront/emerchantpay_threeds/status'
      end

      it 'with threeds_v2_control_device_type' do
        expect(payment.threeds_v2_control_device_type).to eq 'browser'
      end

      it 'with threeds_v2_control_challenge_window_size' do
        expect(payment.threeds_v2_control_challenge_window_size).to eq 'full_screen'
      end

      it 'with threeds_v2_control_challenge_indicator' do
        expect(payment.threeds_v2_control_challenge_indicator).to eq 'no_preference'
      end

      it 'with threeds_v2_merchant_risk_shipping_indicator' do
        expect(payment.threeds_v2_merchant_risk_shipping_indicator).to eq 'stored_address'
      end

      it 'with threeds_v2_merchant_risk_delivery_timeframe' do
        expect(payment.threeds_v2_merchant_risk_delivery_timeframe).to eq 'another_day'
      end

      it 'with threeds_v2_browser_accept_header' do
        expect(payment.threeds_v2_browser_accept_header).to eq '*/*'
      end

      it 'with threeds_v2_browser_java_enabled' do
        expect(payment.threeds_v2_browser_java_enabled).to be true
      end

      it 'with threeds_v2_browser_language' do
        expect(payment.threeds_v2_browser_language).to eq 'en-GB'
      end

      it 'with threeds_v2_browser_color_depth' do
        expect(payment.threeds_v2_browser_color_depth).to eq 32
      end

      it 'with threeds_v2_browser_screen_height' do
        expect(payment.threeds_v2_browser_screen_height).to eq 400
      end

      it 'with threeds_v2_browser_screen_width' do
        expect(payment.threeds_v2_browser_screen_width).to eq 400
      end

      it 'with threeds_v2_browser_time_zone_offset' do
        expect(payment.threeds_v2_browser_time_zone_offset).to eq '+0'
      end

      it 'with threeds_v2_browser_user_agent' do
        expect(payment.threeds_v2_browser_user_agent).to_not be_nil
      end

      it 'with threeds_v2_merchant_risk_reorder_items_indicator' do
        expect(payment.threeds_v2_merchant_risk_reorder_items_indicator).to eq 'first_time'
      end

      it 'with threeds_v2_card_holder_account_creation_date' do
        expect(payment.threeds_v2_card_holder_account_creation_date).to eq DateTime.now.strftime('%d-%m-%Y')
      end

      it 'with threeds_v2_card_holder_account_update_indicator' do
        expect(payment.threeds_v2_card_holder_account_update_indicator).to eq 'current_transaction'
      end

      it 'with threeds_v2_card_holder_account_last_change_date' do
        expect(payment.threeds_v2_card_holder_account_last_change_date).to eq DateTime.now.strftime('%d-%m-%Y')
      end

      it 'with threeds_v2_card_holder_account_password_change_indicator' do
        expect(payment.threeds_v2_card_holder_account_password_change_indicator).to eq 'during_transaction'
      end

      it 'with threeds_v2_card_holder_account_password_change_date' do
        expect(payment.threeds_v2_card_holder_account_password_change_date).to eq DateTime.now.strftime('%d-%m-%Y')
      end

      it 'with threeds_v2_card_holder_account_shipping_address_usage_indicator' do
        expect(payment.threeds_v2_card_holder_account_shipping_address_usage_indicator).to eq 'current_transaction'
      end

      it 'with threeds_v2_card_holder_account_shipping_address_date_first_used' do
        expect(payment.threeds_v2_card_holder_account_shipping_address_date_first_used)
          .to eq DateTime.now.strftime('%d-%m-%Y')
      end

      it 'with threeds_v2_card_holder_account_transactions_activity_last24_hours' do
        expect(payment.threeds_v2_card_holder_account_transactions_activity_last24_hours).to eq 1
      end

      it 'with threeds_v2_card_holder_account_transactions_activity_previous_year' do
        expect(payment.threeds_v2_card_holder_account_transactions_activity_previous_year).to be_nil
      end

      it 'with threeds_v2_card_holder_account_purchases_count_last6_months' do
        expect(payment.threeds_v2_card_holder_account_purchases_count_last6_months).to be_nil
      end

      it 'with threeds_v2_card_holder_account_registration_indicator' do
        expect(payment.threeds_v2_card_holder_account_registration_indicator).to be_nil
      end

      it 'with threeds_v2_card_holder_account_registration_date' do
        expect(payment.threeds_v2_card_holder_account_registration_date).to be_nil
      end
    end

  end

  describe 'when payment with order' do
    let(:order) { create(:order_with_line_items, state: 'complete') }
    let(:order2) do
      create :order_with_line_items, state: 'complete',
             line_items: order.line_items,
             user_id:    order.user_id
    end
    let(:create_completed_order) do
      create :spree_payment,
             payment_method: source.payment_method,
             source: source,
             state: 'completed',
             order: spree_payment.order
    end
    let(:spree_payment) do
      create :spree_payment,
             payment_method: source.payment_method,
             source: source,
             order: order,
             state: 'completed'
    end
    let(:mapped_order_with_line_items) do
      SpreeEmerchantpayGenesis::Mappers::Order.for(
        SpreeEmerchantpayGenesis::Mappers::Order.prepare_data(
          spree_payment.order,
          spree_payment.order.user,
          build(
            :gateway_options_with_address,
            email: spree_payment.order.email,
            currency: spree_payment.order.currency,
            order_number: spree_payment.order.number,
            payment_number: spree_payment.number
          )
        )
      )
    end
    let(:payment) do
      described_class.for_payment(
        gate_request,
        mapped_order_with_line_items,
        emerchantpay_source,
        options
      ).context
    end

    it 'with threeds_v2_card_holder_account_registration_indicator' do
      create_completed_order

      expect(payment.threeds_v2_card_holder_account_registration_indicator).to eq 'current_transaction'
    end

    it 'with threeds_v2_card_holder_account_purchases_count_last6_months' do
      create_completed_order

      expect(payment.threeds_v2_card_holder_account_purchases_count_last6_months).to eq 2
    end

    it 'with reorder threeds_v2_merchant_risk_reorder_items_indicator' do # rubocop:disable RSpec/ExampleLength
      create :spree_payment,
             payment_method: source.payment_method,
             source: source,
             order: order2,
             state: 'completed'

      expect(payment.threeds_v2_merchant_risk_reorder_items_indicator).to eq 'reordered'
    end

    it 'with threeds_v2_card_holder_account_transactions_activity_previous_year' do # rubocop:disable RSpec/ExampleLength
      create :spree_payment,
             payment_method: source.payment_method,
             source: source,
             order: order,
             state: 'completed',
             created_at: Date.current.last_year

      expect(payment.threeds_v2_card_holder_account_transactions_activity_previous_year).to eq 1
    end

    describe 'when digital order' do
      let(:mapped_order_with_line_items) do
        SpreeEmerchantpayGenesis::Mappers::Order.for(
          SpreeEmerchantpayGenesis::Mappers::Order.prepare_data(
            order,
            order.user,
            build(
              :gateway_options_with_address,
              email: order.email,
              currency: order.currency,
              order_number: order.number,
              payment_number: spree_payment.number
            )
          )
        )
      end

      before do
        allow(order).to receive_messages digital?: true
      end

      it 'with threeds_v2_purchase_category' do
        expect(payment.threeds_v2_purchase_category).to eq 'service'
      end

      it 'with threeds_v2_merchant_risk_shipping_indicator' do
        expect(payment.threeds_v2_merchant_risk_shipping_indicator).to eq 'digital_goods'
      end

      it 'with threeds_v2_merchant_risk_delivery_timeframe' do
        expect(payment.threeds_v2_merchant_risk_delivery_timeframe).to eq 'electronic'
      end
    end

    describe 'when guest checkout' do
      let(:mapped_order_with_line_items) do
        order.user_id = nil
        SpreeEmerchantpayGenesis::Mappers::Order.for(
          SpreeEmerchantpayGenesis::Mappers::Order.prepare_data(
            order,
            nil,
            build(
              :gateway_options_with_address,
              email: order.email,
              currency: order.currency,
              order_number: order.number,
              payment_number: spree_payment.number
            )
          )
        )
      end

      it 'with threeds_v2_merchant_risk_reorder_items_indicator' do
        expect(payment.threeds_v2_merchant_risk_reorder_items_indicator).to eq 'first_time'
      end

      it 'with threeds_v2_merchant_risk_shipping_indicator' do
        expect(payment.threeds_v2_merchant_risk_shipping_indicator).to eq 'other'
      end

      it 'wtih threeds_v2_card_holder_account_registration_indicator' do
        expect(payment.threeds_v2_card_holder_account_registration_indicator).to eq 'guest_checkout'
      end
    end
  end

  describe 'when reference' do
    let(:reference) do
      create_emerchantpay_payment

      described_class.for_reference(
        build(:genesis_capture),
        99,
        SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_transaction_id('123456'),
        SpreeEmerchantpayGenesis::Mappers::Order.for(spree_payment.order.attributes.symbolize_keys)
      ).context
    end

    it 'with proper response' do
      expect(reference).to be_a GenesisRuby::Api::Requests::Financial::Capture
    end

    it 'with amount' do
      expect(reference.amount).to eq 99
    end

    it 'with currency' do
      expect(reference.currency).to eq 'EUR'
    end
  end

  describe 'when method continue' do
    let(:method_continue) do
      create_emerchantpay_payment

      described_class.for_method_continue(
        build(:genesis_method_continue),
        SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_transaction_id('123456')
      ).context
    end

    it 'with timestamp' do
      expect(method_continue.transaction_timestamp).to include DateTime.now.strftime('%Y-%m-%dT%H:%M')
    end

    it 'with unique_id' do
      expect(method_continue.transaction_unique_id).to_not be_nil
    end
  end

  describe 'when url!' do
    let(:params) do
      described_class.for_urls!(
        {
          return_success_url: "https://example.com/#{described_class::ORDER_REPLACE_PATTERN}",
          return_failure_url: "https://example.com/#{described_class::ORDER_REPLACE_PATTERN}"
        },
        spree_payment.order.number
      )
    end

    it 'with return_success_url' do
      expect(params[:return_success_url]).to include spree_payment.order.number
    end

    it 'with return_failure_url' do
      described_class.for_urls! params, spree_payment.order.number

      expect(params[:return_failure_url]).to include spree_payment.order.number
    end
  end

  describe 'when wpf' do
    let(:source) do
      create :emerchantpay_checkout_source,
             public_metadata: {
               sale3d: { bin: '420000', tail: '0000' }, trustly_sale: { return_success_url_target: 'top' }
             }
    end
    let(:payment_method) { source.payment_method }
    let(:spree_payment) do
      create :spree_payment,
             payment_method: payment_method,
             source: source,
             order: create(:order_with_line_items)
    end
    let(:options) { described_class.for_urls! spree_payment.payment_method.preferences, spree_payment.order.number }
    let(:mapped_order_with_line_items) do
      SpreeEmerchantpayGenesis::Mappers::Order.for(
        SpreeEmerchantpayGenesis::Mappers::Order.prepare_data(
          spree_payment.order,
          spree_payment.order.user,
          build(
            :gateway_options_with_address,
            email: spree_payment.order.email,
            currency: spree_payment.order.currency,
            order_number: spree_payment.order.number,
            payment_number: spree_payment.number
          )
        )
      )
    end
    let(:gate_request) { build :genesis_wpf }

    before do
      described_class.for_wpf(gate_request, mapped_order_with_line_items, source, options).context
    end

    it 'with description' do
      expect(gate_request.description).to include 'Product', 'x 1'
    end

    it 'with transaction types' do
      expect(gate_request.__send__(:transaction_types))
        .to include({ transaction_type: { '@attributes': { name: 'authorize3d' } } })
    end

    it 'with default transaction types' do # rubocop:disable RSpec/ExampleLength
      options = described_class.for_urls!(
        Spree::Gateway::EmerchantpayCheckout.new.preferences, spree_payment.order.number
      )

      gate_request = build :genesis_wpf

      described_class.for_wpf(gate_request, mapped_order_with_line_items, source, options).context

      expect(gate_request.__send__(:transaction_types))
        .to include({ transaction_type: { '@attributes': { name: 'sale3d' }, bin: '420000', tail: '0000' } })
    end

    it 'when sale3d with custom attributes' do
      expect(gate_request.__send__(:transaction_types))
        .to include({ transaction_type: { '@attributes': { name: 'sale3d' }, bin: '420000', tail: '0000' } })
    end

    it 'when trustly_sale with custom attributes' do
      expect(gate_request.__send__(:transaction_types))
        .to include({ transaction_type: { '@attributes': { name: 'trustly_sale' }, return_success_url_target: 'top' } })
    end

    it 'with default locale' do # rubocop:disable RSpec/ExampleLength
      options = described_class.for_urls!(
        Spree::Gateway::EmerchantpayCheckout.new.preferences, spree_payment.order.number
      )

      gate_request = build :genesis_wpf

      described_class.for_wpf(gate_request, mapped_order_with_line_items, source, options).context

      expect(gate_request.api_config[:url]).to include '/en/wpf'
    end

    describe 'when mobile types' do
      let(:payment_method) do
        payment_method = source.payment_method

        payment_method.preferred_transaction_types.push 'google_pay_authorize', 'apple_pay_sale', 'pay_pal_express'

        payment_method
      end

      it 'with google pay authorize' do
        expect(gate_request.__send__(:transaction_types))
          .to include({ transaction_type: { '@attributes': { name: 'google_pay' }, payment_subtype: 'authorize' } })
      end

      it 'with apple pay sale' do
        expect(gate_request.__send__(:transaction_types))
          .to include({ transaction_type: { '@attributes': { name: 'apple_pay' }, payment_subtype: 'sale' } })
      end

      it 'with pay pal express' do
        expect(gate_request.__send__(:transaction_types))
          .to include({ transaction_type: { '@attributes': { name: 'pay_pal' }, payment_type: 'express' } })
      end

    end

  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers

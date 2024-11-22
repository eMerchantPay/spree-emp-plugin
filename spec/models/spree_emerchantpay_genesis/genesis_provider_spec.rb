# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe SpreeEmerchantpayGenesis::GenesisProvider, :vcr do
  let(:source) { create(:spree_credit_card) }
  let(:spree_payment) do
    create :spree_payment,
           order: create(:order_with_line_items, currency: 'EUR'),
           payment_method: source.payment_method,
           source: source
  end
  let(:options) { spree_payment.payment_method.preferences }

  describe 'when error handling' do
    let(:genesis_provider) do
      described_class.new SpreeEmerchantpayGenesis::PaymentMethodHelper::DIRECT_PAYMENT, options
    end

    describe 'when GenesisRuby Error' do
      before do
        allow(SpreeEmerchantpayGenesis::TransactionHelper)
          .to receive(:init_genesis_req).and_raise GenesisRuby::Error
      end

      it 'with purchase' do
        expect(genesis_provider.purchase).to be_a GenesisRuby::Error
      end
    end

    describe 'when Standard Error' do
      before do
        allow(SpreeEmerchantpayGenesis::TransactionHelper).to receive(:init_genesis_req).and_raise StandardError
      end

      it 'with purchase' do
        expect(genesis_provider.purchase).to be_a GenesisRuby::Error
      end

      it 'with reference' do # rubocop:disable RSpec/ExampleLength
        transaction = create :emerchantpay_payment,
                             transaction_id: 'sp-c6910-b099-48be-ae5e-87f8cac3f',
                             unique_id:      '7e82b1d4eae5ab35c51fbaa68b23bcbd',
                             payment_method: spree_payment.payment_method.type,
                             payment_id:     spree_payment.number,
                             order_id:       spree_payment.order.number,
                             amount:         GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
                               spree_payment.amount.to_s, spree_payment.currency
                             ),
                             currency:       spree_payment.order.currency

        expect(genesis_provider.capture(1, transaction)).to be_a ActiveMerchant::Billing::Response
      end
    end
  end

  describe 'when initialization' do
    it 'with options' do
      expect do
        described_class.new SpreeEmerchantpayGenesis::PaymentMethodHelper::DIRECT_PAYMENT, options
      end.to_not raise_error
    end

    it 'with configuration' do
      genesis_provider = described_class.new(
        SpreeEmerchantpayGenesis::PaymentMethodHelper::DIRECT_PAYMENT,
        spree_payment.payment_method.preferences
      )

      expect(genesis_provider.instance_variable_get(:@configuration)).to be_a GenesisRuby::Configuration
    end

    it 'with checkout method type' do
      genesis_provider = described_class.new(
        SpreeEmerchantpayGenesis::PaymentMethodHelper::CHECKOUT_PAYMENT,
        spree_payment.payment_method.preferences
      )

      expect(genesis_provider.instance_variable_get(:@method_type)).to eq 'emerchantpay_checkout'
    end

    it 'with invalid method type' do
      genesis_provider = described_class.new('invalid', spree_payment.payment_method.preferences)

      expect { genesis_provider.__send__(:init_gateway_req) }.to raise_error GenesisRuby::Error
    end
  end

  describe 'when initialized' do
    let(:genesis_provider) do
      described_class.new SpreeEmerchantpayGenesis::PaymentMethodHelper::DIRECT_PAYMENT, options
    end
    let(:order_data) do
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
    end

    it 'with load data' do
      expect { genesis_provider.load_data order_data }.to_not raise_error
    end

    it 'with load source' do
      expect { genesis_provider.load_source spree_payment.source }.to_not raise_error
    end

    it 'with load payment' do
      expect { genesis_provider.load_payment spree_payment }.to_not raise_error
    end
  end

  describe 'emerchantpay direct processing' do
    let(:order_data) do
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
    let(:genesis_provider) do
      provider = described_class.new SpreeEmerchantpayGenesis::PaymentMethodHelper::DIRECT_PAYMENT, options
      provider.load_data order_data
      provider.load_source(
        build(
          :emerchantpay_credit_card_source,
          payment_method: spree_payment.payment_method,
          user: spree_payment.order.user,
          number: '4938730000000001'
        )
      )
      provider.load_payment spree_payment

      provider
    end

    describe 'when purchase' do
      it 'with proper success response type' do
        response = genesis_provider.purchase

        expect(response).to be_a GenesisRuby::Api::Response
      end

      it 'with approved response state' do
        response = genesis_provider.purchase

        expect(response.approved?).to be true
      end

      it 'with stored emerchantpay payment' do
        response = genesis_provider.purchase
        payment  = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_transaction_id(
          response.response_object[:transaction_id]
        )

        expect(payment.response[:unique_id]).to eq response.response_object[:unique_id]
      end

      it 'with proper error response type' do
        expect(genesis_provider.purchase).to be_a GenesisRuby::Api::Response
      end

      it 'with error response state' do
        response = genesis_provider.purchase

        expect(response.error?).to be true
      end
    end

    describe 'when capture' do
      let(:transaction) do
        create :emerchantpay_payment,
               transaction_id: 'sp-c6910-b099-48be-ae5e-87f8cac3f',
               unique_id:      '7e82b1d4eae5ab35c51fbaa68b23bcbd',
               payment_method: spree_payment.payment_method.name,
               payment_id:     spree_payment.number,
               order_id:       spree_payment.order.number,
               amount:         GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
                 spree_payment.amount.to_s, spree_payment.currency
               ),
               currency:       spree_payment.order.currency
      end

      it 'with proper success response' do
        response = genesis_provider.capture transaction.major_amount, transaction

        expect(response).to be_a ActiveMerchant::Billing::Response
      end

      it 'with proper error response' do
        expect(genesis_provider.capture(transaction.major_amount, transaction))
          .to be_a ActiveMerchant::Billing::Response
      end

      it 'with stored reference payment' do
        genesis_provider.capture(transaction.major_amount, transaction)

        payment = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_unique_id transaction.unique_id

        expect(payment.reference_id).to eq '94f077b6046cf1195260b7324d0df4b7'
      end
    end

    describe 'when refund' do
      let(:transaction) do
        create :emerchantpay_payment,
               transaction_id:   'sp-d8d3d-380a-48ab-b136-dd894711b',
               unique_id:        'ce67aa24ca6ac656684af4a302a6214d',
               payment_method:   spree_payment.payment_method.name,
               transaction_type: 'capture',
               payment_id:       spree_payment.number,
               order_id:         spree_payment.order.number,
               amount:           GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
                 spree_payment.amount.to_s, spree_payment.currency
               ),
               currency:         spree_payment.order.currency
      end

      it 'with proper success response' do
        response = genesis_provider.refund transaction.major_amount, transaction

        expect(response).to be_a ActiveMerchant::Billing::Response
      end

      it 'with proper error response' do
        expect(genesis_provider.refund(transaction.major_amount, transaction))
          .to be_a ActiveMerchant::Billing::Response
      end

      it 'with stored reference payment' do
        genesis_provider.refund transaction.major_amount, transaction

        payment = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_unique_id transaction.unique_id

        expect(payment.reference_id).to eq 'e8ead7e8645a70380c0759e87688881a'
      end
    end

    describe 'when_void' do
      let(:transaction) do
        create :emerchantpay_payment,
               transaction_id:   'sp-ff560-7d56-486b-9b0f-260573cdf',
               unique_id:        'e8ead7e8645a70380c0759e87688881a',
               payment_method:   spree_payment.payment_method.name,
               transaction_type: 'refund',
               payment_id:       spree_payment.number,
               order_id:         spree_payment.order.number,
               amount:           GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
                 spree_payment.amount.to_s, spree_payment.currency
               ),
               currency:         spree_payment.order.currency
      end

      it 'with proper success response' do
        response = genesis_provider.void transaction

        expect(response).to be_a ActiveMerchant::Billing::Response
      end

      it 'with proper error response' do
        expect(genesis_provider.void(transaction)).to be_a ActiveMerchant::Billing::Response
      end

      it 'with stored reference payment' do
        genesis_provider.void transaction

        payment = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_unique_id transaction.unique_id

        expect(payment.reference_id).to eq '6413d2f30e97641479677a1aee7776db'
      end
    end

    describe 'when method continue' do
      let(:payment) do
        create :emerchantpay_payment,
               transaction_id:   'sp-8f095-212d-41f3-8c2c-5da0b1365',
               payment_method:   spree_payment.payment_method.name,
               unique_id:        '162d90bf750a62392b12a88010426ccd',
               reference_id:     nil,
               terminal_token:   'd8fa76066cba4eafcdc53321860e99d6e72ec688',
               status:           'pending_async',
               payment_id:       spree_payment.number,
               order_id:         spree_payment.order.number,
               amount:           11_000,
               currency:         spree_payment.order.currency,
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

      it 'with success 3dsv2 continue request' do
        response = genesis_provider.method_continue payment

        expect(response).to be_a GenesisRuby::Api::Response
      end

      it 'with error 3dsv2 continue request' do
        expect(genesis_provider.method_continue(payment)).to be_a GenesisRuby::Api::Response
      end

      it 'with redirect_url after 3dsv2 continue request' do
        response = genesis_provider.method_continue payment

        expect(response.response_object[:redirect_url])
          .to eq 'https://staging.gate.emerchantpay.net/threeds/authentication/162d90bf750a62392b12a88010426ccd'
      end
    end

    describe 'when notification' do
      let(:params) do
        {
          unique_id: '846b2298647e3b3f7b0067a818113eb1',
          signature: '5f10e44d3789e6bf8e51f06d86a951db24c524cb'
        }
      end
      let(:transaction) do
        create :emerchantpay_payment,
               transaction_id: 'sp-9a508-4b64-4e4c-9636-7fd73889d',
               unique_id:      '846b2298647e3b3f7b0067a818113eb1',
               payment_method: spree_payment.payment_method.name,
               payment_id:     spree_payment.number,
               order_id:       spree_payment.order.number,
               amount:         GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
                 spree_payment.amount.to_s, spree_payment.currency
               ),
               currency:       spree_payment.order.currency
      end

      it 'with successful notification' do
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Notification signature is generated with default password.'
        end

        expect(genesis_provider.notification(transaction, params)).to be_a GenesisRuby::Api::Notification
      end

      it 'with reconcile response' do
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Notification signature is generated with default password.'
        end

        response = genesis_provider.notification transaction, params

        expect(response.reconciliation.response_object[:unique_id]).to eq params[:unique_id]
      end
    end
  end

  describe 'emerchantpay checkout web payment form' do
    let(:source) { create(:emerchantpay_checkout_source) }
    let(:spree_payment) do
      create :spree_payment,
             order: create(:order_with_line_items, currency: 'EUR'),
             payment_method: source.payment_method,
             source: source
    end
    let(:options) { spree_payment.payment_method.preferences }

    let(:order_data) do
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
    let(:genesis_provider) do
      provider = described_class.new SpreeEmerchantpayGenesis::PaymentMethodHelper::CHECKOUT_PAYMENT, options
      provider.load_data order_data
      provider.load_source(
        build(
          :emerchantpay_checkout_source,
          payment_method: spree_payment.payment_method,
          user: spree_payment.order.user
        )
      )
      provider.load_payment spree_payment

      provider
    end

    describe 'when purchase' do
      it 'with proper success response type' do
        response = genesis_provider.purchase

        expect(response).to be_a GenesisRuby::Api::Response
      end

      it 'with approved response state' do
        response = genesis_provider.purchase

        expect(response.new?).to be true
      end

      it 'with stored emerchantpay payment' do
        response = genesis_provider.purchase
        payment  = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_transaction_id(
          response.response_object[:transaction_id]
        )

        expect(payment.response[:unique_id]).to eq response.response_object[:unique_id]
      end

      it 'with proper error response type' do
        expect(genesis_provider.purchase).to be_a GenesisRuby::Api::Response
      end

      it 'with error response state' do
        response = genesis_provider.purchase

        expect(response.error?).to be true
      end
    end

    describe 'when notification' do
      let(:params) do
        {
          wpf_unique_id:                 'ae1d51e6dcaae88635bb54b2aaa3257a',
          signature:                     'd80593dfdb3959842fd028f74ccd356a5b124c65',
          payment_transaction_unique_id: '09dc2c787080b29b2552daf3fb639712'
        }
      end
      let(:transaction) do
        create :emerchantpay_payment,
               transaction_id: 'sp-1ac50-75f8-48f9-a0e8-fc294ee02',
               unique_id:      'eafae2b35722a68ed9e4522ace7d720b',
               payment_method: spree_payment.payment_method.name,
               payment_id:     spree_payment.number,
               order_id:       spree_payment.order.number,
               amount:         GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
                 spree_payment.amount.to_s, spree_payment.currency
               ),
               currency:       spree_payment.order.currency
      end

      it 'with successful notification' do
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Notification signature is generated with default password.'
        end

        expect(genesis_provider.notification(transaction, params)).to be_a GenesisRuby::Api::Notification
      end

      it 'with reconcile response' do
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Notification signature is generated with default password.'
        end

        response = genesis_provider.notification transaction, params

        expect(response.reconciliation.response_object[:unique_id]).to eq params[:wpf_unique_id]
      end

      it 'with reference reconcile response' do # rubocop:disable RSpec/ExampleLength
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Notification signature is generated with default password.'
        end

        transaction = create :emerchantpay_payment,
                             transaction_id: 'sp-1ac50-75f8-48f9-a0e8-fc294ee02',
                             unique_id:      '09dc2c787080b29b2552daf3fb639712',
                             payment_method: spree_payment.payment_method.name,
                             payment_id:     spree_payment.number,
                             order_id:       spree_payment.order.number,
                             amount:         GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
                               spree_payment.amount.to_s, spree_payment.currency
                             ),
                             currency:       spree_payment.order.currency

        response        = genesis_provider.notification transaction, params
        response_object = genesis_provider.__send__(
          :fetch_reconciliation_object, response.reconciliation, transaction.unique_id
        )

        expect(response_object[:status]).to eq 'refunded'
      end
    end
  end

  describe 'when smart router' do
    let(:options) do
      preferences = spree_payment.payment_method.preferences
      preferences[:token] = ''

      preferences
    end
    let(:order_data) do
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
    let(:genesis_provider) do
      provider = described_class.new SpreeEmerchantpayGenesis::PaymentMethodHelper::DIRECT_PAYMENT, options
      provider.load_data order_data
      provider.load_source(
        build(
          :emerchantpay_credit_card_source,
          payment_method: spree_payment.payment_method,
          user: spree_payment.order.user,
          number: '4938730000000001'
        )
      )
      provider.load_payment spree_payment

      provider
    end
    let(:transaction) do
      create :emerchantpay_payment,
             transaction_id: 'sp-9a508-4b64-4e4c-9636-7fd73889d',
             unique_id:      '846b2298647e3b3f7b0067a818113eb1',
             payment_method: spree_payment.payment_method.name,
             payment_id:     spree_payment.number,
             order_id:       spree_payment.order.number,
             amount:         GenesisRuby::Utils::MoneyFormat.amount_to_exponent(
               spree_payment.amount.to_s, spree_payment.currency
             ),
             currency:       spree_payment.order.currency,
             terminal_token: ''
    end

    it 'with init gateway req' do
      genesis_provider.__send__ :init_gateway_req

      expect(genesis_provider.instance_variable_get(:@configuration).force_smart_routing).to be_truthy
    end

    it 'with configure token' do
      genesis_provider.__send__(:configure_token, transaction)

      expect(genesis_provider.instance_variable_get(:@configuration).force_smart_routing).to be_truthy
    end

    describe 'when notification' do
      let(:params) do
        {
          unique_id:      '846b2298647e3b3f7b0067a818113eb1',
          signature:      '5f10e44d3789e6bf8e51f06d86a951db24c524cb',
          terminal_token: '123456'
        }
      end

      it 'without smart router' do
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Notification signature is generated with default password.'
        end

        genesis_provider.notification(transaction, params)

        expect(genesis_provider.instance_variable_get(:@configuration).force_smart_routing).to be_falsey
      end

      it 'with terminal token from ipn' do
        if Rails.application.credentials[:genesis]
          skip 'Skipped: Secrets file is used. Notification signature is generated with default password.'
        end

        genesis_provider.notification(transaction, params)

        expect(genesis_provider.instance_variable_get(:@configuration).token).to eq '123456'
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers

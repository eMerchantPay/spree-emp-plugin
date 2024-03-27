module SpreeEmerchantpayGenesis
  module Base
    # Base Gateway object
    class Gateway < Spree::Gateway

      preference :username, :string
      preference :password, :string
      preference :return_success_url, :string, default: 'http://localhost:4000/orders/|:ORDER:|'
      preference :return_failure_url, :string, default: 'http://localhost:4000/checkout/payment?order_number=|:ORDER:|'
      preference :threeds_allowed, :boolean_select, default: true
      preference :challenge_indicator, :select, default: lambda {
        {
          values:   GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::Control::
              ChallengeIndicators.all,
          selected: GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::Control::
              ChallengeIndicators::NO_PREFERENCE
        }
      }
      preference :hostname, :string, default: 'http://127.0.0.1:4000'
      preference :test_mode, :boolean_select, default: true

      def provider_class
        SpreeEmerchantpayGenesis::GenesisProvider
      end

      def provider
        @provider = provider_class.new method_type, options if @provider.nil?

        @provider
      end

      def authorize(money_in_cents, source, gateway_options)
        purchase money_in_cents, source, gateway_options
      end

      # Capture authorized payment
      def capture(amount, transaction_id, gateway_options)
        order, payment = order_data_from_options gateway_options

        prepare_provider order.attributes.symbolize_keys.merge(gateway_options), payment.source, payment

        transaction = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_transaction_id transaction_id

        provider.capture GenesisRuby::Utils::MoneyFormat.exponent_to_amount(amount, order.currency), transaction
      end

      # Undo a payment
      def void(transaction_id, gateway_options)
        order, payment = order_data_from_options gateway_options

        prepare_provider order.attributes.symbolize_keys.merge(gateway_options), payment.source, payment

        transaction = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_final_transaction transaction_id

        provider.void transaction
      end

      # Refund a payment
      def credit(credit_cents, transaction_id, refund_object)
        payment = refund_object[:originator].payment
        order   = refund_object[:originator].payment.order

        prepare_provider order.attributes.symbolize_keys, payment.source, payment

        transaction = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_final_transaction transaction_id

        provider.refund GenesisRuby::Utils::MoneyFormat.exponent_to_amount(credit_cents, order.currency), transaction
      end

      def payment_profiles_supported?
        false
      end

      def supports?(_source)
        true
      end

      def order_data_from_options(options)
        order_number, payment_number = options[:order_id].split('-')
        order = Spree::Order.find_by(number: order_number)
        payment = order.payments.find_by(number: payment_number)
        [order, payment]
      end

    end
  end
end

module SpreeEmerchantpayGenesis
  module Base
    # Base Gateway object
    class Gateway < Spree::Gateway

      preference :username, :string
      preference :password, :string
      preference :transaction_types, :select,  default: -> { { values: [:authorize, :authorize3d, :sale, :sale3d] } }
      preference :return_success_url, :string, default: 'http://localhost:4000/orders/|:ORDER:|'
      preference :return_failure_url, :string, default: 'http://localhost:4000/checkout/payment?order_number=|:ORDER:|'
      preference :threeds_allowed, :boolean, default: true
      preference :challenge_indicator, :select, default: lambda {
        { values: [:no_preference, :no_challenge_requested, :preference, :mandate] }
      }
      preference :hostname, :string, default: 'http://127.0.0.1:4000'

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

      def order_data_from_options(options)
        order_number, payment_number = options[:order_id].split('-')
        order = Spree::Order.find_by(number: order_number)
        payment = order.payments.find_by(number: payment_number)
        [order, payment]
      end

    end
  end
end

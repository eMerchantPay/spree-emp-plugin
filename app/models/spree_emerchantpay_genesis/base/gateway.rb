module SpreeEmerchantpayGenesis
  module Base
    # Base Gateway object
    class Gateway < Spree::Gateway

      preference :username, :string
      preference :password, :string
      preference :transaction_types, :select,  default: -> { { values: [:authorize, :authorize3d, :sale, :sale3d] } }
      preference :return_success_url, :string
      preference :return_failure_url, :string

      def settle(_amount, _checkout, _gateway_options)
        puts 'SETTLE'
      end

      def capture(_amount, _transaction_id, _gateway_options)
        puts 'CAPTURE'
      end

      def void(_transaction_id, _data)
        puts 'VOID'
      end

      def credit(_credit_cents, _transaction_id, _options)
        puts 'CREDIT'
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

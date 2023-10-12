module SpreeEmerchantpayGenesis
  # Emerchantpay Payments Repository
  class EmerchantpayPaymentsRepository

    class << self

      # Find all payments that belong to an order
      def find_all_by_order_and_payment(order_id, payment_id)
        Db::EmerchantpayPayment.where(order_id: order_id, payment_id: payment_id)
      end

      # Store Genesis Payment to the DB
      def save_from_response_data(genesis_request, genesis_response, order, spree_payment)
        payment                   = Db::EmerchantpayPayment.new
        genesis_response          = genesis_response.response_object
        formatted_genesis_request = format_genesis_request(genesis_request)

        map_payment spree_payment.payment_method.type, payment, formatted_genesis_request, genesis_response

        payment.order_id   = order.number
        payment.payment_id = spree_payment.number

        payment.save
      end

      private

      # Map the given data to the Emerchantpay Payment
      def map_payment(payment_method, genesis_payment, genesis_request, genesis_response) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        genesis_payment.transaction_id    = genesis_response[:transaction_id]
        genesis_payment.unique_id         = genesis_response[:unique_id]
        genesis_payment.payment_method    = payment_method
        genesis_payment.terminal_token    = fetch_token genesis_request, genesis_response
        genesis_payment.status            = genesis_response[:status]
        genesis_payment.transaction_type  = genesis_response[:transaction_type]
        genesis_payment.amount            = format_amount genesis_response[:amount], genesis_response[:currency]
        genesis_payment.currency          = genesis_response[:currency]
        genesis_payment.mode              = genesis_response[:mode]
        genesis_payment.message           = genesis_response[:message]
        genesis_payment.technical_message = genesis_response[:technical_message]
        genesis_payment.request           = filter_genesis_parameters genesis_request
        genesis_payment.response          = genesis_response
      end

      # Format major amount to minor currency
      def format_amount(amount, currency)
        GenesisRuby::Utils::MoneyFormat.amount_to_exponent amount, currency
      end

      # Convert Genesis Request object to hash
      def format_genesis_request(genesis_request)
        ActiveSupport::JSON.decode genesis_request.to_json
      end

      # Fetch the terminal token used for the payment
      def fetch_token(request, response)
        return response[:terminal_token] if response[:terminal_token]

        request['configuration']['token'] if request['configuration']
      end

      # Filter CC parameters
      def filter_genesis_parameters(genesis_request)
        return genesis_request['tree_structure'] unless genesis_request['tree_structure']['payment_transaction']

        genesis_request['tree_structure']['payment_transaction'].reject do |key|
          %w(card_holder card_number expiration_month expiration_year cvv).include? key
        end
      end

    end

  end
end

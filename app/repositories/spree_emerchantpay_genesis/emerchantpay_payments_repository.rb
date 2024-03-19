module SpreeEmerchantpayGenesis
  # Emerchantpay Payments Repository
  class EmerchantpayPaymentsRepository

    class << self

      # Find by transaction_id
      def find_by_transaction_id(transaction_id)
        Db::EmerchantpayPayment.find_by(transaction_id: transaction_id)
      end

      # Find by unique_id
      def find_by_unique_id(unique_id)
        Db::EmerchantpayPayment.find_by(unique_id: unique_id)
      end

      # Find all payments that belong to an order
      def find_all_by_order_and_payment(order_id, payment_id)
        Db::EmerchantpayPayment.where(order_id: order_id, payment_id: payment_id).order('id desc')
      end

      # Store Genesis Payment to the DB
      def save_from_response_data(genesis_request, genesis_response, order, spree_payment)
        payment                   = Db::EmerchantpayPayment.new
        formatted_genesis_request = format_genesis_request(genesis_request)

        map_payment spree_payment, payment, formatted_genesis_request, genesis_response

        payment.order_id   = order.number
        payment.payment_id = spree_payment.number

        payment.save
      end

      # Update Existing payment
      def update_from_response_data(emerchantpay_payment, response_object, spree_payment)
        request = { configuration: {
          token: emerchantpay_payment.terminal_token || response_object[:terminal_token]
        } }.with_indifferent_access
        response_object[:mode] = emerchantpay_payment.mode unless response_object.key? :mode

        map_payment spree_payment, emerchantpay_payment, request, response_object

        emerchantpay_payment.save
      end

      # Save the reference id to the original transaction
      def save_reference_from_transaction(transaction, reference_id)
        transaction.reference_id = reference_id
        transaction.save
      end

      # Find the transaction with the latest payment state
      def find_final_transaction(transaction_id)
        transaction = find_by_transaction_id transaction_id

        if transaction&.reference_id
          reference = find_by_unique_id transaction.reference_id

          # check for second level of reference
          return find_by_unique_id reference.reference_id if reference&.reference_id

          return reference
        end

        transaction
      end

      private

      # Map the given data to the Emerchantpay Payment
      def map_payment(spree_payment, genesis_payment, genesis_request, genesis_response) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        currency = genesis_response[:currency] || spree_payment.currency
        amount   = genesis_response[:amount] ? format_amount(genesis_response[:amount], genesis_response[:currency]) : 0

        genesis_payment.transaction_id    = genesis_response[:transaction_id]
        genesis_payment.unique_id         = genesis_response[:unique_id]
        genesis_payment.payment_method    = spree_payment.payment_method.type
        genesis_payment.terminal_token    = fetch_token genesis_request, genesis_response
        genesis_payment.status            = genesis_response[:status]
        genesis_payment.transaction_type  = genesis_response[:transaction_type]
        genesis_payment.amount            = amount
        genesis_payment.currency          = currency
        genesis_payment.mode              = genesis_response[:mode]
        genesis_payment.message           = genesis_response[:message]
        genesis_payment.technical_message = genesis_response[:technical_message]
        genesis_payment.request           = filter_request genesis_request if genesis_request.key?('tree_structure')
        genesis_payment.response          = genesis_payment.response.merge genesis_response
        genesis_payment.updated_at        = DateTime.now
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
      def filter_request(genesis_request)
        return genesis_request['tree_structure'] unless genesis_request['tree_structure']['payment_transaction']

        genesis_request['tree_structure']['payment_transaction'].reject do |key|
          %w(card_holder card_number expiration_month expiration_year cvv).include? key
        end
      end

    end

  end
end

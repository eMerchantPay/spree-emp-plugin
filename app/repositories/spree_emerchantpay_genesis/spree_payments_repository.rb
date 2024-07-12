module SpreeEmerchantpayGenesis
  # Spree Payments Repository
  class SpreePaymentsRepository

    class << self

      # Find Spree payment by its number
      def find_by_number(number)
        Spree::Payment.find_by(number: number)
      end

      # Update Spree payment from response
      def update_payment(payment, response_object)
        payment.cvv_response_code = response_object[:cvv_result_code] if response_object.key?(:cvv_result_code)
        payment.avs_response      = response_object[:avs_response_code] if response_object.key?(:avs_response_code)

        # From Spree Payment Model
        #     # transaction_id is  much easier to understand
        #     def transaction_id
        #       response_code
        #     end
        payment.response_code     = response_object[:transaction_id]
      end

      # Add metadata to the Payment model
      def add_payment_metadata(payment, options, genesis_response, response_object)
        redirect_url      = TransactionHelper.fetch_redirect_url(options, genesis_response)
        state             = response_object.key?(:status) ? { state: response_object[:status] } : {}
        message           = response_object.key?(:message) ? { message: response_object[:message] } : {}
        technical_message =
          response_object.key?(:technical_message) ? { message: response_object[:technical_message] } : {}

        payment.private_metadata.merge! redirect_url, message, technical_message, state
      end

      # Update the Spree Payment status from GenesisRuby::Api::Response object
      def update_payment_status(payment, response, transaction_type)
        if response.approved?
          action = :complete
          action = :pend if capturable_type? payment, transaction_type

          payment.public_send(action)
        end

        payment.failure if TransactionHelper.failure_result? response
        payment.void if response.voided?
      end

      # Determine if the given transaction type need capture reference action
      def capturable_type?(payment, transaction_type)
        capturable_types = GenesisRuby::Utils::Transactions::References::CapturableTypes

        if SpreeEmerchantpayGenesis::Mappers::Transaction::MOBILE_TYPES.include? transaction_type
          return mobile_authorize_type? payment, transaction_type
        end

        capturable_types.allowed_reference? transaction_type
      end

      # Determine if the given mobile type is authorize or not
      def mobile_authorize_type?(payment, transaction_type)
        transaction_helper    = SpreeEmerchantpayGenesis::Mappers::Transaction
        selected_mobile_types = SpreeEmerchantpayGenesis::PaymentMethodHelper.fetch_wpf_mobile_types(
          payment.payment_method.preferred_transaction_types
        )

        if selected_mobile_types.is_a?(Hash) && selected_mobile_types.key?(transaction_type)
          custom_attribute     = selected_mobile_types[transaction_type.to_s]
          custom_attribute_key = transaction_helper.mobile_subtype_key transaction_type

          return custom_attribute[custom_attribute_key.to_s] == transaction_helper::MOBILE_PAYMENT_SUB_TYPE_AUTHORIZE
        end

        false
      end

    end

  end
end

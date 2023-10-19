module SpreeEmerchantpayGenesis
  # Spree Payments Repository
  class SpreePaymentsRepository

    class << self

      # Update Spree payment from response
      def update_payment(payment, response)
        response_object = response.response_object

        payment.cvv_response_code = response_object[:cvv_result_code]
        payment.avs_response      = response_object[:avs_response_code]

        # From Spree Payment Model
        #     # transaction_id is  much easier to understand
        #     def transaction_id
        #       response_code
        #     end
        payment.response_code     = response_object[:transaction_id]
      end

      # Add metadata to the Payment model
      def add_payment_metadata(payment, response_object)
        redirect_url      = response_object[:redirect_url] ? { redirect_url: response_object[:redirect_url] } : {}
        message           = response_object[:message] ? { message: response_object[:message] } : {}
        technical_message = response_object[:technical_message] ? { message: response_object[:technical_message] } : {}

        payment.private_metadata.merge! redirect_url, message, technical_message
      end

    end

  end
end

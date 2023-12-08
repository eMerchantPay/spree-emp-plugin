module SpreeEmerchantpayGenesis
  module Threeds
    # 3DSv2 Callback Handler service
    class Callback < Base::PaymentService

      class << self

        # Service caller
        def call(params)
          new params
        end

      end

      # Store 3DSv2 callback payment status
      def store_callback_status
        # Validate Callback post params against params[:signature]
        validate_callback_signature

        emerchantpay_payment.callback_status = params[:threeds_method_status]
        emerchantpay_payment.save
      rescue StandardError => e
        Rails.logger.error e.message
      end

      # Retrieve the stored callback status
      def fetch_callback_status
        emerchantpay_payment.callback_status.to_s
      end

      # Execute Method Continue and read the response
      def process_method_continue
        # Validate Method Continue params against params[:signature]
        validate_3ds_signature

        handle_method_continue_response genesis_provider.method_continue(emerchantpay_payment)
      rescue StandardError => e
        Rails.logger.error e.message

        genesis_preferences[:return_failure_url]
      end

      private

      # Check the given callback signature
      def validate_callback_signature
        raise 'Invalid signature' unless ThreedsHelper.validate_callback_signature(
          params[:signature], params[:unique_id], params[:threeds_method_status], genesis_preferences[:password]
        )
      end

      # Handle Method Continue Genesis Response Object
      def handle_method_continue_response(response)
        return genesis_preferences[:return_success_url] if response.approved?
        return response.response_object[:redirect_url] if response.pending_async?

        genesis_preferences[:return_failure_url]
      end

    end
  end
end

require 'spree/gateway/emerchantpay_direct'

module SpreeEmerchantpayGenesis
  module Threeds
    # Method Continue service
    class MethodContinue < Base::PaymentService

      class << self

        # Service caller
        def call(params)
          new params
        end

      end

      def initialize(params)
        super params

        # Validate params
        validate_params
      end

      # 3DSv2 Secure Method Continue logic
      def build_secure_method_params
        {
          unique_id:          emerchantpay_payment.unique_id,
          signature:          generate_3ds_signature,
          threeds_method_url: emerchantpay_payment.response[:threeds_method_url],
          failure_url:        failure_url
        }
      end

      private

      # Validate checksum
      def validate_params
        checksum = generate_checksum

        raise 'Invalid request!' unless checksum == @params[:checksum]
      end

      # Get Order Number
      def order_number
        order&.number
      end

      # Failure URL
      def failure_url
        genesis_preferences[:return_failure_url].sub(GenesisProvider::ORDER_REPLACE_PATTERN, order_number)
      end

    end
  end
end

module SpreeEmerchantpayGenesis
  module Base
    # Payment Service Base class
    class PaymentService

      attr_reader :params, :emerchantpay_payment, :order, :spree_payment, :genesis_provider

      # Constructor
      def initialize(params)
        @params               = params
        @emerchantpay_payment = fetch_emerchantapy_payment
        @order                = load_order
        @spree_payment        = load_spree_payment
        @genesis_provider     = initialize_genesis_provider
      end

      protected

      # Fetch emerchantpay payment
      def fetch_emerchantapy_payment
        result = SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_by_unique_id(params[:unique_id])

        raise 'Invalid parameters given. Payment not found.' unless result

        result
      end

      # Load the Order using the payment
      def load_order
        SpreeEmerchantpayGenesis::SpreeOrderRepository.find_by_number @emerchantpay_payment[:order_id]
      end

      # Load the Spree Payment record
      def load_spree_payment
        @order.payments.find_by(number: @emerchantpay_payment[:payment_id])
      end

      # Initialize the payment provider
      def initialize_genesis_provider
        provider = SpreeEmerchantpayGenesis::GenesisProvider.new genesis_preferences
        provider.load_source spree_payment.source
        provider.load_data SpreeEmerchantpayGenesis::Mappers::Order.for order.attributes.symbolize_keys
        provider.load_payment spree_payment

        provider
      end

      # Check 3DSv2 request against the given signature
      def validate_3ds_signature
        raise 'Invalid 3DS signature' unless @params[:signature] == generate_3ds_signature
      end

      # Generate 3DSv2 signature
      def generate_3ds_signature
        GenesisRuby::Utils::Threeds::V2.generate_signature(
          unique_id:         emerchantpay_payment.unique_id,
          amount:            emerchantpay_payment.amount,
          timestamp:         emerchantpay_payment.zulu_response_timestamp,
          merchant_password: genesis_preferences[:password]
        )
      end

      # Generate Checksum
      def generate_checksum
        TransactionHelper.generate_checksum(
          {
            unique_id: emerchantpay_payment.unique_id,
            amount:    emerchantpay_payment.major_amount,
            currency:  emerchantpay_payment.currency
          }
        )
      end

      private

      # Prepare Genesis Preferences
      def genesis_preferences
        @spree_payment.payment_method.preferences.merge token: @emerchantpay_payment[:terminal_token]
      end

    end
  end
end

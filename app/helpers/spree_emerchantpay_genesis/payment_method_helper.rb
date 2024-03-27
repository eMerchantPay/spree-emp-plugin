module SpreeEmerchantpayGenesis
  # Helper methods used in the transaction processing
  class PaymentMethodHelper

    DIRECT_PAYMENT   = 'emerchantpay_direct'.freeze
    CHECKOUT_PAYMENT = 'emerchantpay_checkout'.freeze

    class << self

      # Fetch the Payment type from the given Payment Method
      def fetch_method_type(payment_method)
        case payment_method
        when Spree::Gateway::EmerchantpayDirect.name
          DIRECT_PAYMENT
        when Spree::Gateway::EmerchantpayCheckout.name
          CHECKOUT_PAYMENT
        else
          ''
        end
      end

      # Build Checkout source attribute if source_attributes are not present?
      def default_checkout_source_attributes(order)
        default_attr = { name: CHECKOUT_PAYMENT }

        default_attr.merge!({ consumer_email: order.email }) if order&.email

        default_attr
      end

      # Get default values for select options
      def select_options_value(options, key)
        return options[key][:selected] if options[key].is_a? Hash

        options[key]
      end

    end

  end
end

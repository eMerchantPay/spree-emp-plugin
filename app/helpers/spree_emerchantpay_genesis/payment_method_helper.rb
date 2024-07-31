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

      # Provide a list of the available transaction types for the checkout payment method configuration
      def fetch_wpf_transaction_types
        types = Mappers::Transaction.exclude_wpf_types GenesisRuby::Utils::Transactions::WpfTypes.all

        Mappers::Transaction.map_wpf_config_mobile_types types
      end

      # Extract Custom Attributes defined along with the transaction types
      def fetch_wpf_mobile_types(selected_transaction_types)
        attributes            = {}
        selected_mobile_types = selected_transaction_types.intersection(
          Mappers::Transaction.mobile_types_with_payment_sub_types
        )

        selected_mobile_types.each do |type|
          attributes.merge! Mappers::Transaction.extract_mobile_type_with_sub_type type
        end

        attributes
      end

    end

  end
end

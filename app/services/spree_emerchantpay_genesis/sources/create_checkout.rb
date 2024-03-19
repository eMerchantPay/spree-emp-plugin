module SpreeEmerchantpayGenesis
  module Sources
    # Alternative for Spree::Wallet::CreatePaymentSource
    # Serve Web Payment Form Checkout payment method
    class CreateCheckout

      prepend Spree::ServiceModule::Base

      def call(payment_method:, params: {}, order: nil)
        source = payment_method.payment_source_class.new source_attributes(payment_method, params, order)

        source.save ? success(source) : failure(source)
      end

      private

      # Checkout source attributes
      def source_attributes(payment_method, params, order) # rubocop:disable Metrics/MethodLength
        user    = order&.user
        default = PaymentMethodHelper.default_checkout_source_attributes order

        default[:payment_method_id] = payment_method.id
        default[:user_id]           = user&.id

        return default unless params.present?

        default.merge(
          {
            name:             params[:name] || default[:name],
            consumer_id:      params[:consumer_id],
            consumer_email:   params[:consumer_email] || default[:consumer_email],
            public_metadata:  params[:public_metadata],
            private_metadata: params[:private_metadata]
          }
        )
      end

    end
  end
end

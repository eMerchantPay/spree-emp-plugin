module SpreeEmerchantpayGenesis
  module Sources
    # Alternative for Spree::Wallet::CreatePaymentSource
    # Add number and verification_value for memory usage of CC data via V2::Checkout#payment_create
    class CreateCreditCard

      prepend Spree::ServiceModule::Base

      def call(payment_method:, params: {}, user: nil)
        return failure nil, :missing_attributes if params.nil?

        source = payment_method.payment_source_class.new source_attributes(payment_method, params, user)

        source.save ? success(source) : failure(source)
      end

      private

      # Credit Card source attributes
      def source_attributes(payment_method, params, user) # rubocop:disable Metrics/MethodLength
        {
          payment_method_id:           payment_method.id,
          user_id:                     user&.id,
          gateway_payment_profile_id:  params[:gateway_payment_profile_id],
          gateway_customer_profile_id: params[:gateway_customer_profile_id],
          last_digits:                 params[:last_digits],
          month:                       params[:month],
          year:                        params[:year],
          name:                        params[:name],
          number:                      params[:number],
          verification_value:          params[:verification_value]
        }
      end

    end
  end
end

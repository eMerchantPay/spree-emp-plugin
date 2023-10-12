module Spree
  module Payments
    # Decorate Source creation logic
    module CreateDecorator

      prepend Spree::ServiceModule::Base

      def find_or_create_payment_source(order:, params:, payment_attributes:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        payment_method = payment_attributes[:payment_method]

        if payment_method&.source_required?
          if order.user.present? && params[:source_id].present?
            source = payment_method.payment_source_class.find_by(id: params[:source_id], user: order.user)

            return failure(nil, :source_not_found) if source.nil?
          else
            result = create_payment_source payment_method, params, order

            return failure(nil, result.error.value) if result.failure?

            source = result.value
          end

          payment_attributes[:source] = source
        end

        success(order: order, payment_attributes: payment_attributes)
      end

      private

      # Create payment source
      def create_payment_source(payment_method, params, order)
        if payment_method.type == Spree::Gateway::EmerchantpayDirect.name
          emerchantpay_direct_payment_source payment_method, params, order
        else
          default_payment_source payment_method, params, order
        end
      end

      # Spree default payment source creation
      def default_payment_source(payment_method, params, order)
        Wallet::CreatePaymentSource.call(
          payment_method: payment_method,
          params: params.delete(:source_attributes),
          user: order.user
        )
      end

      # Emerchantpay Direct payment source creation
      def emerchantpay_direct_payment_source(payment_method, params, order)
        SpreeEmerchantpayGenesis::Sources::CreateCreditCard.call(
          payment_method: payment_method,
          params: params.delete(:source_attributes),
          user: order.user
        )
      end

    end
  end
end

::Spree::Payments::Create.prepend(Spree::Payments::CreateDecorator)

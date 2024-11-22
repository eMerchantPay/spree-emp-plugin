module Spree
  module Api
    module V2
      module Storefront
        # Decorate Create Payment action
        module CheckoutControllerDecorator

          def complete
            spree_authorize! :update, spree_current_order, order_token

            result = complete_service.call(order: spree_current_order)

            return emerchantpay_checkout_handler if result.success? && emerchantpay_checkout_method?

            render_order(result)
          end

          def next
            spree_authorize! :update, spree_current_order, order_token

            result = next_service.call(order: spree_current_order)

            return emerchantpay_checkout_handler if result.success? && emerchantpay_checkout_method?

            render_order(result)
          end

          def create_payment
            result = create_payment_service.call(order: spree_current_order, params: params)

            if result.success?
              return emerchantpay_direct_payment_handler if emerchantpay_direct_method?

              render_serialized_payload(201) { serialize_resource(spree_current_order.reload) }
            else
              render_error_payload(result.error)
            end
          end

          private

          # Handle EmerchantpayDirect Payment Method Create Payment API Call
          def emerchantpay_direct_payment_handler
            spree_authorize! :update, spree_current_order, order_token

            # Complete the order. This will call the purchase method with source containing credit card number
            loop { break unless spree_current_order.next }

            return handle_order_state 201 if spree_current_order.completed?

            render_error_payload(spree_current_order.errors[:base].join('|'))
          end

          # Handle Emerchantpay Checkout Payment Method Next and Complete API Calls
          def emerchantpay_checkout_handler
            handle_order_state
          end

          # Check if the payment is made via emerchantpay direct method
          def emerchantpay_direct_method?
            spree_current_order&.payments &&
              spree_current_order.payments.last.payment_method.type == Spree::Gateway::EmerchantpayDirect.name
          end

          # Check if the payment is made via emerchantpay checkout method
          def emerchantpay_checkout_method?
            spree_current_order&.completed? && spree_current_order.payments &&
              spree_current_order.payments.last.payment_method.type == Spree::Gateway::EmerchantpayCheckout.name
          end

          # Generate Spree Response
          def handle_order_state(status = 200)
            render_serialized_payload(status) do
              response = serialize_resource(spree_current_order.reload)

              response[:data].merge!(build_genesis_response_parameters)

              response
            end
          end

          # Build additional response parameters
          def build_genesis_response_parameters
            spree_payment = spree_current_order.payments.last.private_metadata

            { emerchantpay_payment: { state: spree_payment[:state], redirect_url: spree_payment[:redirect_url] } }
          end

        end
      end
    end
  end
end

::Spree::Api::V2::Storefront::CheckoutController.prepend(Spree::Api::V2::Storefront::CheckoutControllerDecorator)

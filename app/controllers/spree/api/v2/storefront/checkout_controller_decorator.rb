module Spree
  module Api
    module V2
      module Storefront
        # Decorate Create Payment action
        module CheckoutControllerDecorator

          def create_payment
            result = create_payment_service.call(order: spree_current_order, params: params)

            if result.success?
              return emerchantpay_direct_payment_handler if
                result.value.payment_method.type == Spree::Gateway::EmerchantpayDirect.name

              render_serialized_payload(201) { serialize_resource(spree_current_order.reload) }
            else
              render_error_payload(result.error)
            end
          end

          private

          # Handle EmerchantpayDirect Payment Method Create Payment API Call
          def emerchantpay_direct_payment_handler
            return render_error_payload('You must authenticate in order to create Emerchanptpay payment') if
              order_token.empty?

            spree_authorize! :update, spree_current_order, order_token

            # Complete the order. This will call the purchase method with source containing credit card number
            loop { break unless spree_current_order.next }

            handle_order_state
          end

          # Generate Spree Response
          def handle_order_state
            #  spree_current_order.payments.last.source

            if spree_current_order.completed?
              return render_serialized_payload(201) do
                response = serialize_resource(spree_current_order.reload)

                response[:data].merge!(build_genesis_response_parameters)

                response
              end
            end

            render_error_payload(spree_current_order.errors[:base].join('|'))
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

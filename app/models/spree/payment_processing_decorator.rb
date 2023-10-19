module Spree
  # Emerchantpay Payment Processing decorator
  module PaymentProcessingDecorator

    def gateway_action(source, action, success_state)
      protect_from_connection_error do
        response      = payment_method.__send__ action, money.money.cents, source, gateway_options
        success_state = fetch_state success_state, response, action
        result        = SpreeEmerchantpayGenesis::TransactionHelper.generate_spree_response response
        handle_response(result, success_state, :failure)
      end
    end

    private

    # Provide Spree success event method that will be executed
    def fetch_state(current_state, response, action)
      return current_state unless %w(purchase authorize).include? action.to_s
      return current_state unless response.instance_of? GenesisRuby::Api::Response
      return 'started_processing' if SpreeEmerchantpayGenesis::TransactionHelper.async_result?(response)

      current_state
    end

  end
end

::Spree::Payment.prepend(Spree::PaymentProcessingDecorator)

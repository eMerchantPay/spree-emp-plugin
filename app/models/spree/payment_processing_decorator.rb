module Spree
  # Emerchantpay Payment Processing decorator
  module PaymentProcessingDecorator

    def gateway_action(source, action, success_state)
      protect_from_connection_error do
        response      = payment_method.__send__(action, money.money.cents, source, gateway_options)
        success_state = fetch_state(success_state, response, action)
        result        = fetch_response(response)
        handle_response(result, success_state, :failure)
      end
    end

    private

    def fetch_state(current_state, response, action)
      return current_state unless %w(purchase authorize).include? action.to_s
      return current_state unless response.instance_of? GenesisRuby::Api::Response
      return 'started_processing' if async_result?(response)

      current_state
    end

    def fetch_response(response)
      return build_response response if response.instance_of? GenesisRuby::Api::Response
      return build_failure_error response if response.is_a? StandardError

      response
    end

    # Build Success or Failure Spree Response
    def build_response(response)
      return build_success_response response if success_result? response

      build_failure_response response
    end

    # Build Success Spree Response from GenesisRuby::Api::Response
    def build_success_response(response)
      ActiveMerchant::Billing::Response.new true, build_message(response)
    end

    # Build Failure Spree Response from GenesisRuby::Api:Response
    def build_failure_response(response)
      ActiveMerchant::Billing::Response.new false, build_message(response)
    end

    # Build Failure Spree Response from GenesisRuby::Error
    def build_failure_error(error)
      ActiveMerchant::Billing::Response.new false, error.message
    end

    # Check given response for success result
    def success_result?(response)
      response.approved? || async_result?(response)
    end

    # Check given response for asynchronous execution
    def async_result?(response)
      response.pending? || response.pending_async? || response.in_progress? || response.pending_hold?
    end

    # Build message from the given response
    def build_message(response)
      result  = response.response_object
      message = ''

      message = result[:message] unless result[:message].nil?
      message = "#{message} (#{result[:technical_message]})" unless result[:technical_message].nil?

      message
    end

  end
end

::Spree::Payment.prepend(Spree::PaymentProcessingDecorator)

module SpreeEmerchantpayGenesis
  # Genesis API provider
  class GenesisProvider # rubocop:disable Metrics/ClassLength

    attr_reader :provider_data

    # Constructor
    def initialize(method_type, options)
      @options       = options
      @configuration = Mappers::Genesis.for_config(@options).context
      @method_type   = method_type
    end

    # Load Order data
    def load_data(data)
      @order = data

      parse_order_patterns

      @order
    end

    # Load Payment Source data
    def load_source(source)
      @source = source
    end

    # Load Payment data
    def load_payment(payment)
      @payment = payment
    end

    # Create a payment
    def purchase
      safe_execute do
        genesis = init_gateway_req

        response = genesis.execute.response

        handle_response genesis.request, response

        response
      end
    end

    # Capture a payment
    def capture(amount, transaction)
      configure_token transaction

      safe_execute(is_reference: true) do
        genesis_request = TransactionHelper.init_reference_req(
          TransactionHelper::CAPTURE_ACTION, @configuration, transaction.transaction_type
        )
        genesis         = GenesisRuby::Genesis.new(
          @configuration, Mappers::Genesis.for_reference(genesis_request, amount, transaction, @order).context
        )

        process_reference_response transaction, genesis_request, genesis.execute.response
      end
    end

    # Refund a payment
    def refund(amount, transaction)
      configure_token transaction

      safe_execute(is_reference: true) do
        genesis_request = TransactionHelper.init_reference_req(
          TransactionHelper::REFUND_ACTION, @configuration, transaction.transaction_type
        )
        genesis         = GenesisRuby::Genesis.new(
          @configuration, Mappers::Genesis.for_reference(genesis_request, amount, transaction, @order).context
        )

        process_reference_response transaction, genesis_request, genesis.execute.response
      end
    end

    # Cancel a payment
    def void(transaction)
      configure_token transaction

      safe_execute(is_reference: true) do
        genesis_request = TransactionHelper.init_reference_req(
          TransactionHelper::VOID_ACTION, @configuration, transaction.transaction_type
        )
        genesis         = GenesisRuby::Genesis.new(
          @configuration, Mappers::Genesis.for_reference(genesis_request, nil, transaction, @order).context
        )

        process_reference_response transaction, genesis_request, genesis.execute.response
      end
    end

    # Handle notification
    def notification(emerchantpay_payment, params)
      notification = TransactionHelper.init_notification @configuration, params

      notification.reconcile

      unless notification.transaction_reconciliation?
        reconciliation = notification.reconciliation

        raise reconciliation.nil? ? 'Notification can not be handled!' : reconciliation.response_object.inspect
      end

      handle_reconciliation_response emerchantpay_payment, notification.reconciliation

      notification
    end

    # Execute 3DSv2 Method Continue
    def method_continue(emerchantpay_payment)
      method_continue = TransactionHelper.init_method_continue_req @configuration

      genesis = GenesisRuby::Genesis.new(
        @configuration, Mappers::Genesis.for_method_continue(method_continue, emerchantpay_payment).context
      )

      genesis.execute.response
    end

    private

    # Process Gateway response
    def process_reference_response(original_transaction, genesis_request, genesis_response)
      response_object = genesis_response.response_object

      if TransactionHelper.success_result? genesis_response
        # Code format that suit plugin generation
        EmerchantpayPaymentsRepository.save_reference_from_transaction(
          original_transaction, response_object[:unique_id]
        )
      end

      handle_response genesis_request, genesis_response, is_payment: false

      TransactionHelper.generate_spree_response genesis_response
    end

    # Handle Genesis Response
    def handle_response(request, response, is_payment: true)
      response_object = fetch_response_object response

      if TransactionHelper.can_save_genesis_response? response_object
        EmerchantpayPaymentsRepository.save_from_response_data request, response_object, @order, @payment
      end

      SpreePaymentsRepository.update_payment @payment, response_object if is_payment
      SpreePaymentsRepository.add_payment_metadata @payment, @options, response, response_object

      # Missing shipping amount fix
      @payment.amount = response.response_object[:amount] if response.response_object&.key?(:amount) && is_payment

      @payment.save

      Rails.logger.info response.response_object.to_yaml
      true
    end

    # Handle Genesis Notification Response
    def handle_reconciliation_response(emerchantpay_payment, reconciliation)
      response_object = fetch_reconciliation_object reconciliation, emerchantpay_payment.unique_id

      EmerchantpayPaymentsRepository.update_from_response_data emerchantpay_payment, response_object, @payment

      SpreePaymentsRepository.update_payment @payment, response_object
      SpreePaymentsRepository.add_payment_metadata @payment, @options, reconciliation, response_object
      SpreePaymentsRepository.update_payment_status @payment, reconciliation, response_object[:transaction_type]

      @payment.save

      Rails.logger.info reconciliation.response_object.to_yaml
      true
    end

    # Protect Genesis request execution inside block
    def safe_execute(is_reference: false, &block)
      block.call
    rescue GenesisRuby::Error => e
      Rails.logger.error e.message

      return TransactionHelper.generate_spree_response e if is_reference

      e
    rescue StandardError => e
      Rails.logger.error e.message

      return TransactionHelper.generate_spree_response e if is_reference

      GenesisRuby::Error.new(e.message)
    end

    # Configure Genesis provider with the token form the given transaction
    def configure_token(transaction)
      @configuration.token = transaction.terminal_token if transaction.terminal_token
    end

    # Plugin options with dynamic parameters
    def parse_order_patterns
      Mappers::Genesis.for_urls! @options, @order[:number]

      @options
    end

    # Initialize Gateway API Request
    def init_gateway_req
      case @method_type
      when PaymentMethodHelper::CHECKOUT_PAYMENT
        init_wpf_api
      when PaymentMethodHelper::DIRECT_PAYMENT
        init_processing_api
      else
        raise GenesisRuby::Error, 'Invalid Payment Method Type given!'
      end
    end

    # Init Processing API Request
    def init_processing_api
      genesis_request = TransactionHelper.init_genesis_req @configuration, @options[:transaction_types]

      GenesisRuby::Genesis.new(
        @configuration,
        Mappers::Genesis.for_payment(genesis_request, @order, @source, @options).context
      )
    end

    # Init WPF API Request
    def init_wpf_api
      genesis_request = TransactionHelper.init_wpf_req @configuration

      GenesisRuby::Genesis.new(
        @configuration,
        Mappers::Genesis.for_wpf(genesis_request, @order, @source, @options).context
      )
    end

    # Prepare the response object
    def fetch_response_object(genesis_response)
      response_object = genesis_response.response_object
      test_mode       = ActiveModel::Type::Boolean.new.cast(@options[:test_mode]) ? 'test' : 'live'

      if @method_type == PaymentMethodHelper::CHECKOUT_PAYMENT && genesis_response.new?
        response_object.merge!(
          { transaction_type: TransactionHelper::WPF_TRANSACTION_TYPE, mode: test_mode, terminal_token: '' }
        )
      end

      response_object
    end

    # Fetch the payment_transaction object from the given reconciliation response
    def fetch_reconciliation_object(reconciliation, unique_id)
      response_object = reconciliation.response_object

      return response_object unless response_object.key? :payment_transaction
      return response_object[:payment_transaction] if response_object[:payment_transaction].is_a? Hash

      response_object[:payment_transaction].select { |payment| payment[:unique_id] == unique_id }.first
    end

  end
end

module SpreeEmerchantpayGenesis
  # Genesis API provider
  class GenesisProvider

    attr_reader :provider_data

    # Constructor
    def initialize(options)
      @options           = options
      @configuration     = Mappers::Genesis.for_config(@options).context
    end

    # Load Order data
    def load_data(data)
      @order = data
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
        genesis_request = TransactionHelper.init_genesis_req @configuration, @options[:transaction_types]

        genesis = GenesisRuby::Genesis.new(
          @configuration,
          Mappers::Genesis.for_payment(genesis_request, @order, @source, @options).context
        )

        response = genesis.execute.response

        handle_response genesis_request, response

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

    private

    # Process Gateway response
    def process_reference_response(original_transaction, genesis_request, genesis_response)
      response_object = genesis_response.response_object

      if TransactionHelper.success_result? genesis_response
        EmerchantpayPaymentsRepository.save_reference_from_transaction(
          original_transaction,
          response_object[:unique_id]
        )
      end

      handle_response genesis_request, genesis_response, is_payment: false

      TransactionHelper.generate_spree_response genesis_response
    end

    # Handle Genesis Response
    def handle_response(request, response, is_payment: true)
      if TransactionHelper.can_save_genesis_response? response
        EmerchantpayPaymentsRepository.save_from_response_data request, response, @order, @payment
      end

      SpreePaymentsRepository.update_payment @payment, response if is_payment
      SpreePaymentsRepository.add_payment_metadata @payment, response.response_object

      @payment.save

      Rails.logger.info response.response_object.to_yaml
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

  end
end

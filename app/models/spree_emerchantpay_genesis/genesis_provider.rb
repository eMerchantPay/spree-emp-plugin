module SpreeEmerchantpayGenesis
  # Genesis API provider
  class GenesisProvider

    attr_reader :provider_data

    # Constructor
    def initialize(options)
      @options         = options
      @configuration   = genesis_provider_configuration
      @genesis_request = initialize_genesis_client options
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
    def purchase # rubocop:disable Metrics/MethodLength
      genesis = GenesisRuby::Genesis.new(
        @configuration,
        Mappers::Genesis.for(@genesis_request, @order, @source, @options).genesis_request
      )

      response = genesis.execute.response

      handle_response response

      response
    rescue GenesisRuby::Error => e
      Rails.logger.error e.message
      e
    rescue StandardError => e
      Rails.logger.error e.message
      GenesisRuby::Error.new(e.message)
    end

    # Type that require Capture
    def authorization_types
      [
        GenesisRuby::Api::Constants::Transactions::AUTHORIZE,
        GenesisRuby::Api::Constants::Transactions::AUTHORIZE_3D
      ]
    end

    private

    # Handle Genesis Response
    def handle_response(response)
      if can_save_response? response
        EmerchantpayPaymentsRepository.save_from_response_data @genesis_request, response, @order, @payment
      end

      update_payment response

      Rails.logger.info response.response_object.to_yaml
      true
    end

    # Load GenesisRuby configuration object
    def genesis_provider_configuration
      method_options = @options

      configuration             = GenesisRuby::Configuration.new
      configuration.username    = method_options[:username]
      configuration.password    = method_options[:password]
      configuration.token       = method_options[:token]
      configuration.environment = fetch_genesis_environment
      configuration.endpoint    = GenesisRuby::Api::Constants::Endpoints::EMERCHANTPAY

      configuration
    end

    # Fetch genesis_request_type from plugin options
    def initialize_genesis_client(options)
      case options[:transaction_types]
      when 'authorize' then GenesisRuby::Api::Requests::Financial::Cards::Authorize.new @configuration
      when 'authorize3d' then GenesisRuby::Api::Requests::Financial::Cards::Authorize3d.new @configuration
      when 'sale' then GenesisRuby::Api::Requests::Financial::Cards::Sale.new @configuration
      when 'sale3d' then GenesisRuby::Api::Requests::Financial::Cards::Sale3d.new @configuration
      else
        raise "Invalid transaction type given for #{self.class}"
      end
    end

    # Fetch Genesis Environments
    def fetch_genesis_environment
      case @options[:test_mode]
      when true then GenesisRuby::Api::Constants::Environments::STAGING
      else
        GenesisRuby::Api::Constants::Environments::PRODUCTION
      end
    end

    # Update Spree payment from response
    def update_payment(response)
      response_object = response.response_object

      @payment.cvv_response_code    = response_object[:cvv_result_code]
      @payment.avs_response         = response_object[:avs_response_code]

      # From Spree Payment Model
      #     # transaction_id is much easier to understand
      #     def transaction_id
      #       response_code
      #     end
      @payment.response_code        = response_object[:transaction_id]

      add_payment_metadata response_object

      @payment.save
    end

    # Add metadata to the Payment model
    def add_payment_metadata(response_object)
      redirect_url      = response_object[:redirect_url] ? { redirect_url: response_object[:redirect_url] } : {}
      message           = response_object[:message] ? { message: response_object[:message] } : {}
      technical_message = response_object[:technical_message] ? { message: response_object[:technical_message] } : {}

      @payment.private_metadata.merge! redirect_url, message, technical_message
    end

    # Check if the given Genesis Response can be stored
    def can_save_response?(response)
      response_object = response.response_object

      response_object[:transaction_id] && response_object[:currency] && response_object[:amount] &&
        response_object[:mode]
    end

  end
end

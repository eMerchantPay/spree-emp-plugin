module SpreeEmerchantpayGenesis
  # Helper methods used in the transaction processing
  class TransactionHelper # rubocop:disable Metrics/ClassLength

    TRANSACTION_ID_PREFIX = 'sp-'.freeze
    CAPTURE_ACTION        = 'capture'.freeze
    REFUND_ACTION         = 'refund'.freeze
    VOID_ACTION           = 'void'.freeze
    WPF_TRANSACTION_TYPE  = 'checkout'.freeze

    class << self

      include Spree::Core::Engine.routes.url_helpers

      # Generate Transaction Id
      def generate_transaction_id
        "#{TRANSACTION_ID_PREFIX}#{SecureRandom.uuid[TRANSACTION_ID_PREFIX.length..]}"[0..32].downcase
      end

      # Checks if the given request is asynchronous or not
      def asyn?(genesis_request)
        genesis_request.instance_of?(GenesisRuby::Api::Requests::Financial::Cards::Authorize3d) ||
          genesis_request.instance_of?(GenesisRuby::Api::Requests::Financial::Cards::Sale3d)
      end

      # Check given response for success result
      def success_result?(response)
        response.approved? || async_result?(response)
      end

      # Check given response for asynchronous execution
      def async_result?(response)
        response.pending? || response.pending_async? || response.in_progress? || response.pending_hold? || response.new?
      end

      # Check given response for Method Continue parameters
      def threeds_secure?(response)
        TransactionHelper.async_result?(response) && response.response_object&.key?(:threeds_method_url)
      end

      # Check given response for failure
      def failure_result?(response)
        response.error? || response.declined? || response.timeout?
      end

      # Generate Spree Response from Gateway action
      def generate_spree_response(gateway_response)
        return build_spree_response gateway_response if gateway_response.instance_of? GenesisRuby::Api::Response
        return build_failure_error gateway_response if gateway_response.is_a? StandardError

        gateway_response
      end

      # Build message from the given response
      def build_message(response)
        result  = response.response_object
        message = ''

        message = result[:message] unless result[:message].nil?
        message = "#{message} (#{result[:technical_message]})" unless result[:technical_message].nil?

        message
      end

      # Fetch the given string with Genesis Ruby transaction class
      def fetch_genesis_transaction_class(transaction_type)
        request_class = Mappers::Transaction.for transaction_type

        raise "Invalid transaction type given for #{self.class}" if request_class.nil?

        request_class
      end

      # Check if the given Genesis Response can be stored
      def can_save_genesis_response?(response_object)
        !(
          response_object[:transaction_id].nil? ||
            response_object[:transaction_type].nil? ||
            response_object[:mode].nil?
        )
      end

      # Fetch genesis_request_type from plugin options
      def init_genesis_req(configuration, transaction_type)
        request_class = TransactionHelper.fetch_genesis_transaction_class(transaction_type)

        request_class&.new configuration
      end

      # Initialize Genesis client based on the action
      def init_reference_req(action, configuration, transaction_type)
        genesis_request = __send__("initialize_#{action}_client", configuration, transaction_type)

        unless genesis_request
          raise(GenesisRuby::Error, "Invalid #{action.capitalize} action for #{transaction_type.capitalize}")
        end

        genesis_request
      end

      # Init Notification object
      def init_notification(configuration, params)
        GenesisRuby::Api::Notification.new configuration, params
      end

      # Initialize Method Continue Transaction Request
      def init_method_continue_req(configuration)
        GenesisRuby::Api::Requests::Financial::Cards::Threeds::V2::MethodContinue.new configuration
      end

      # Initialize WPF API Request
      def init_wpf_req(configuration)
        GenesisRuby::Api::Requests::Wpf::Create.new configuration
      end

      # Fetch Redirect Url from Genesis Response
      def fetch_redirect_url(options, response)
        url = ''
        url = options[:return_success_url] if TransactionHelper.success_result? response
        url = options[:return_failure_url] if TransactionHelper.failure_result? response
        url = response.response_object[:redirect_url] if response.response_object&.key? :redirect_url
        url = build_threeds_secure_endpoint options, response if TransactionHelper.threeds_secure? response

        { redirect_url: url }
      end

      # Generate Checksum from the response object
      def generate_checksum(response_object)
        Digest::MD5.hexdigest(
          "#{response_object[:unique_id]}#{response_object[:amount]}#{response_object[:currency]}"
        )
      end

      private

      # Build Success or Failure Spree Response
      def build_spree_response(response)
        return build_success_response response if success_result? response

        build_failure_response response
      end

      # Build Success Spree Response from GenesisRuby::Api::Response
      def build_success_response(response)
        ActiveMerchant::Billing::Response.new true, build_message(response), test: test_mode?(response)
      end

      # Build Failure Spree Response from GenesisRuby::Api:Response
      def build_failure_response(response)
        ActiveMerchant::Billing::Response.new false, build_message(response), test: test_mode?(response)
      end

      # Build Failure Spree Response from GenesisRuby::Error
      def build_failure_error(error)
        ActiveMerchant::Billing::Response.new false, error.message
      end

      # Check the given Genesis Response mode (test/production)
      def test_mode?(response)
        response&.response_object&.[](:mode) == 'test'
      end

      # Initialize Genesis Client with Capture request
      def initialize_capture_client(configuration, payment_type)
        return nil unless GenesisRuby::Utils::Transactions::References::CapturableTypes.allowed_reference? payment_type

        init_genesis_req(
          configuration,
          GenesisRuby::Utils::Transactions::References::CapturableTypes.fetch_reference(payment_type)
        )
      end

      # Initialize Genesis Client with Refund request
      def initialize_refund_client(configuration, payment_type)
        return nil unless GenesisRuby::Utils::Transactions::References::RefundableTypes.allowed_reference? payment_type

        init_genesis_req(
          configuration,
          GenesisRuby::Utils::Transactions::References::RefundableTypes.fetch_reference(payment_type)
        )
      end

      # Initialize Genesis with Void request
      def initialize_void_client(configuration, payment_type)
        return nil unless GenesisRuby::Utils::Transactions::References::VoidableTypes.allowed_reference? payment_type

        init_genesis_req(
          configuration,
          GenesisRuby::Utils::Transactions::References::VoidableTypes.fetch_reference(payment_type)
        )
      end

      # Build 3DSv2 Method Continue endpoint
      def build_threeds_secure_endpoint(options, response)
        response_object = response.response_object
        checksum        = generate_checksum response_object

        "#{options[:hostname]}#{emerchantpay_threeds_form_path(response_object[:unique_id], checksum)}"
      end

    end

  end
end

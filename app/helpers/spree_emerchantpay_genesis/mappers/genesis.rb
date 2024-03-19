require 'securerandom'

module SpreeEmerchantpayGenesis
  module Mappers
    # Genesis Gateway Data Mapper
    class Genesis # rubocop:disable Metrics/ClassLength

      ORDER_REPLACE_PATTERN = '|:ORDER:|'.freeze

      include Spree::Core::Engine.routes.url_helpers

      attr_reader :context

      # Load GenesisRuby configuration object
      def self.for_config(options)
        this = new GenesisRuby::Configuration.new

        this.map_config options
      end

      # Provider Data
      def self.for_payment(genesis, order, source, options)
        this = new genesis

        this.map order, source, options
      end

      # Reference Provider
      def self.for_reference(genesis, amount, transaction, order)
        this = new genesis

        this.map_reference amount, transaction, order
      end

      # Map 3D Secure Method Continue from the initial payment response
      def self.for_method_continue(genesis, emerchantpay_payment)
        this = new genesis

        this.map_method_continue emerchantpay_payment
      end

      def self.for_wpf(genesis, order, source, options)
        this = new genesis

        this.map_wpf order, source, options
      end

      # Replace URL patterns
      def self.for_urls!(options, order_number)
        options[:return_success_url]&.sub! ORDER_REPLACE_PATTERN, order_number
        options[:return_failure_url]&.sub! ORDER_REPLACE_PATTERN, order_number
        options[:return_cancel_url]&.sub! ORDER_REPLACE_PATTERN, order_number
        options[:return_pending_url]&.sub! ORDER_REPLACE_PATTERN, order_number

        options
      end

      def initialize(object)
        @context = object
      end

      # Map Financial transaction
      def map(order, source, options)
        common_attributes order
        credit_card_attributes source
        billing_attributes order
        shipping_attributes order
        asyn_attributes options if TransactionHelper.asyn? @context

        if TransactionHelper.asyn?(@context) && ActiveModel::Type::Boolean.new.cast(options[:threeds_allowed])
          threeds_processing_attributes order, source, options
        end

        self
      end

      # Map WPF request
      def map_wpf(order, _source, options)
        common_attributes order, support_ip: false
        billing_attributes order
        shipping_attributes order
        asyn_attributes options
        transaction_types_attributes options
        threeds_wpf_attributes order, options if ActiveModel::Type::Boolean.new.cast options[:threeds_allowed]

        @context.return_cancel_url  = options[:return_cancel_url]
        @context.return_pending_url = options[:return_pending_url]

        self
      end

      # Map Reference transaction
      def map_reference(amount, transaction, order)
        @context.transaction_id = TransactionHelper.generate_transaction_id
        @context.reference_id   = transaction.unique_id
        @context.amount         = amount unless amount.nil?
        @context.currency       = transaction.currency unless amount.nil?
        @context.remote_ip      = order.ip
        @context.usage          =
          "#{I18n.t("reference", scope: "emerchantpay.payment")} - #{transaction.transaction_type.capitalize}"

        self
      end

      # Map Configuration
      def map_config(options)
        @context.username    = options[:username]
        @context.password    = options[:password]
        @context.token       = options[:token] || nil
        @context.environment = fetch_genesis_environment ActiveModel::Type::Boolean.new.cast(options[:test_mode])
        @context.endpoint    = GenesisRuby::Api::Constants::Endpoints::EMERCHANTPAY

        self
      end

      # Map payment data to hash used for 3DS method continue execution
      def map_method_continue(emerchantpay_payment)
        @context.transaction_unique_id = emerchantpay_payment.unique_id
        @context.amount                = emerchantpay_payment.amount
        @context.transaction_timestamp = emerchantpay_payment.zulu_response_timestamp

        self
      end

      private

      # Common Genesis Attributes
      def common_attributes(provider, support_ip: true) # rubocop:disable Metrics/AbcSize
        @context.transaction_id = TransactionHelper.generate_transaction_id
        @context.amount         = provider.total.to_s
        @context.currency       = provider.currency
        @context.usage          = I18n.t 'usage', scope: 'emerchantpay.payment'
        @context.customer_email = provider.email
        @context.customer_phone = provider.billing_address&.phone
        @context.remote_ip      = provider.ip if support_ip

        nil
      end

      # Credit Card Attributes
      def credit_card_attributes(source)
        @context.card_holder      = source.name
        @context.card_number      = source.number
        @context.expiration_month = source.month
        @context.expiration_year  = source.year
        @context.cvv              = source.verification_value

        nil
      end

      # Billing Attributes
      def billing_attributes(provider) # rubocop:disable Metrics/AbcSize
        return unless provider&.billing_address

        @context.billing_first_name = provider.billing_address.first_name
        @context.billing_last_name  = provider.billing_address.last_name
        @context.billing_address1   = provider.billing_address.address1
        @context.billing_address2   = provider.billing_address.address2
        @context.billing_zip_code   = provider.billing_address.zip
        @context.billing_city       = provider.billing_address.city
        @context.billing_state      = provider.billing_address.state
        @context.billing_country    = provider.billing_address.country

        nil
      end

      # Shipping Attributes
      def shipping_attributes(provider) # rubocop:disable Metrics/AbcSize
        return unless provider&.shipping_address

        @context.shipping_first_name = provider.shipping_address.first_name
        @context.shipping_last_name  = provider.shipping_address.last_name
        @context.shipping_address1   = provider.shipping_address.address1
        @context.shipping_address2   = provider.shipping_address.address2
        @context.shipping_zip_code   = provider.shipping_address.zip
        @context.shipping_city       = provider.shipping_address.city
        @context.shipping_state      = provider.shipping_address.state
        @context.shipping_country    = provider.shipping_address.country

        nil
      end

      # Asynchronous attributes
      def asyn_attributes(options)
        @context.notification_url   = "#{options[:hostname]}#{api_v2_storefront_emerchantpay_notification_path}"
        @context.return_success_url = options[:return_success_url]
        @context.return_failure_url = options[:return_failure_url]

        nil
      end

      # Fetch Genesis Environments
      def fetch_genesis_environment(mode)
        case mode
        when true then GenesisRuby::Api::Constants::Environments::STAGING
        else
          GenesisRuby::Api::Constants::Environments::PRODUCTION
        end
      end

      # 3DSv2 Processing attributes
      def threeds_processing_attributes(order, source, options)
        ThreedsAttributes.for_payment @context, order, source, options
      end

      # 3DSv2 WPF attributes
      def threeds_wpf_attributes(order, options)
        ThreedsAttributes.for_wpf @context, order, options
      end

      # Map WPF Transaction Types
      def transaction_types_attributes(options)
        options[:transaction_types].each do |type|
          @context.add_transaction_type type unless type.empty?
        end
      end

    end
  end
end

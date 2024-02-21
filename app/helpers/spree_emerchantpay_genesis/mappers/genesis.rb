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

      # Replace URL patterns
      def self.for_urls!(options, order_number)
        options[:return_success_url]&.sub! ORDER_REPLACE_PATTERN, order_number
        options[:return_failure_url]&.sub! ORDER_REPLACE_PATTERN, order_number

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
        if TransactionHelper.asyn? @context
          asyn_attributes options
          threeds_attributes order, source, options if ActiveModel::Type::Boolean.new.cast options[:threeds_allowed]
        end

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
        @context.token       = options[:token]
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
      def common_attributes(provider) # rubocop:disable Metrics/AbcSize
        @context.transaction_id = TransactionHelper.generate_transaction_id
        @context.amount         = provider.total.to_s
        @context.currency       = provider.currency
        @context.usage          = I18n.t 'usage', scope: 'emerchantpay.payment'
        @context.customer_email = provider.email
        @context.customer_phone = provider.billing_address&.phone
        @context.remote_ip      = provider.ip
      end

      # Credit Card Attributes
      def credit_card_attributes(source)
        @context.card_holder      = source.name
        @context.card_number      = source.number
        @context.expiration_month = source.month
        @context.expiration_year  = source.year
        @context.cvv              = source.verification_value
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
      end

      def asyn_attributes(options)
        @context.notification_url   = "#{options[:hostname]}#{api_v2_storefront_emerchantpay_notification_path}"
        @context.return_success_url = options[:return_success_url]
        @context.return_failure_url = options[:return_failure_url]
      end

      # Fetch Genesis Environments
      def fetch_genesis_environment(mode)
        case mode
        when true then GenesisRuby::Api::Constants::Environments::STAGING
        else
          GenesisRuby::Api::Constants::Environments::PRODUCTION
        end
      end

      # 3DSv2 attributes
      def threeds_attributes(order, source, options) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        user_orders = []
        @context.threeds_v2_purchase_category = fetch_threeds_category order
        @context.threeds_v2_method_callback_url =
          "#{options[:hostname]}#{api_v2_storefront_emerchantpay_threeds_callback_handler_path}"
        threeds_control_attributes options
        @context.threeds_v2_merchant_risk_shipping_indicator = fetch_shipping_indicator order
        @context.threeds_v2_merchant_risk_delivery_timeframe = fetch_delivery_timeframe order
        threeds_browser_attributes source

        user_orders = SpreeOrderRepository.orders_by_user order.user_id if order.user_id
        @context.threeds_v2_merchant_risk_reorder_items_indicator = fetch_reorder_items_indicator order, user_orders

        if order.user.empty?
          @context.threeds_v2_card_holder_account_registration_indicator = GenesisRuby::Api::Constants::Transactions::
              Parameters::Threeds::Version2::CardHolderAccount::RegistrationIndicators::GUEST_CHECKOUT
        end

        threeds_card_holder_attributes order, user_orders unless order.user.empty?
      end

      # 3DSv2 Control attributes
      def threeds_control_attributes(options)
        @context.threeds_v2_control_device_type           = GenesisRuby::Api::Constants::Transactions::Parameters::
            Threeds::Version2::Control::DeviceTypes::BROWSER
        @context.threeds_v2_control_challenge_window_size =
          GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::Control::ChallengeWindowSizes::
              FULLSCREEN
        @context.threeds_v2_control_challenge_indicator   = options[:challenge_indicator]
      end

      # 3DSv2 Browser attributes
      def threeds_browser_attributes(source) # rubocop:disable Metrics/AbcSize
        @context.threeds_v2_browser_accept_header    = source.public_metadata[:accept_header]
        @context.threeds_v2_browser_java_enabled     = ActiveModel::Type::Boolean.new.cast(
          source.public_metadata[:java_enabled]
        )
        @context.threeds_v2_browser_language         = source.public_metadata[:language]
        @context.threeds_v2_browser_color_depth      = source.public_metadata[:color_depth]
        @context.threeds_v2_browser_screen_height    = source.public_metadata[:screen_height]
        @context.threeds_v2_browser_screen_width     = source.public_metadata[:screen_width]
        @context.threeds_v2_browser_time_zone_offset = source.public_metadata[:time_zone_offset]
        @context.threeds_v2_browser_user_agent       = source.public_metadata[:user_agent]
      end

      # Fetch 3DSv2 Purchase Category
      def fetch_threeds_category(order)
        if order.digital
          return GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::Purchase::Categories::SERVICE
        end

        GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::Purchase::Categories::GOODS
      end

      # Fetch 3DSv2 Merchant Risk Shipping Indicator
      def fetch_shipping_indicator(order) # rubocop:disable Metrics/MethodLength
        if order.digital
          return GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::
              ShippingIndicators::DIGITAL_GOODS
        end

        if order.shipping_address&.to_s == order.billing_address&.to_s
          return GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::
              ShippingIndicators::SAME_AS_BILLING
        end

        if order.user_id
          return GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::
              ShippingIndicators::STORED_ADDRESS
        end

        GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::
            ShippingIndicators::OTHER
      end

      # Fetch 3DSv2 Merchant Risk Delivery Timeframe
      def fetch_delivery_timeframe(order)
        if order.digital
          return GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::
              DeliveryTimeframes::ELECTRONICS
        end

        GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::DeliveryTimeframes::
            ANOTHER_DAY
      end

      # Fetch 3DSv2 Merchant Risk Reorder Items Indicator
      def fetch_reorder_items_indicator(order, user_orders) # rubocop:disable Metrics/MethodLength
        unless order.user_id
          return GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::
            ReorderItemIndicators::FIRST_TIME
        end

        variants = []
        order.line_items.each { |line_item| variants.push line_item[:variant_id] }

        reordered = SpreeEmerchantpayGenesis::SpreeOrderRepository.reordered_variant? order.id, variants, user_orders

        if reordered
          return GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::
            ReorderItemIndicators::REORDERED
        end

        GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::MerchantRisk::
            ReorderItemIndicators::FIRST_TIME
      end

      # 3DSv2 Card Holder Account attributes
      def threeds_card_holder_attributes(order, user_orders) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        @context.threeds_v2_card_holder_account_creation_date = order.user.created_at_formatted

        # Card Holder last changes with the 3DS requester
        card_holder_updated_at = ThreedsHelper.fetch_last_change_date(
          order.user.billing_address, order.user.shipping_address
        )
        @context.threeds_v2_card_holder_account_update_indicator = ThreedsHelper.fetch_class_indicator(
          'UpdateIndicators', card_holder_updated_at
        )
        @context.threeds_v2_card_holder_account_last_change_date = card_holder_updated_at

        # Card Holder Password changes
        @context.threeds_v2_card_holder_account_password_change_indicator = ThreedsHelper.fetch_class_indicator(
          'PasswordChangeIndicators', order.user.updated_at_formatted
        )
        @context.threeds_v2_card_holder_account_password_change_date = order.user.updated_at_formatted

        # Card Holder Shipping Address first time used
        shipping_address_first_used = ThreedsHelper.fetch_shipping_address_first_used(order.user.shipping_address)
        @context.threeds_v2_card_holder_account_shipping_address_usage_indicator = ThreedsHelper.fetch_class_indicator(
          'ShippingAddressUsageIndicators', shipping_address_first_used
        )
        @context.threeds_v2_card_holder_account_shipping_address_date_first_used = shipping_address_first_used

        # Card Holder Payments count
        activity_last24_hours = ThreedsHelper.filter_transaction_activity_24_hours user_orders
        if activity_last24_hours.positive?
          @context.threeds_v2_card_holder_account_transactions_activity_last24_hours = activity_last24_hours
        end

        previous_year_count = ThreedsHelper.filter_transaction_activity_previous_year user_orders
        if previous_year_count.positive?
          @context.threeds_v2_card_holder_account_transactions_activity_previous_year = previous_year_count
        end

        purchases_last6_months = SpreeEmerchantpayGenesis::ThreedsHelper.filter_purchases_count_last6_months user_orders
        if purchases_last6_months.positive?
          @context.threeds_v2_card_holder_account_purchases_count_last6_months = purchases_last6_months
        end

        # Card Holder registration with the 3D requester
        first_completed_payment = ThreedsHelper.filter_first_completed_payment user_orders
        unless first_completed_payment.empty?
          string_date = DateTime.parse(first_completed_payment['payment_created_at'].to_s)
                                .strftime(ThreedsHelper::DATE_ISO_FORMAT)
          @context.threeds_v2_card_holder_account_registration_indicator = ThreedsHelper.fetch_class_indicator(
            'RegistrationIndicators', string_date
          )
          @context.threeds_v2_card_holder_account_registration_date = string_date
        end

        nil
      end

    end
  end
end

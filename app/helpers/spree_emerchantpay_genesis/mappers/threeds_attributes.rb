module SpreeEmerchantpayGenesis
  module Mappers
    # Threeds V2 attributes Data Mapper
    class ThreedsAttributes # rubocop:disable Metrics/ClassLength

      attr_reader :context

      include Spree::Core::Engine.routes.url_helpers

      class << self

        # Assign 3DSv2 attributes used for processing payments
        def for_payment(genesis, order, source, options)
          this = new genesis

          this.map_processing_payment order, source, options
        end

        # Assign 3DSv2 attributes used for wpf payments
        def for_wpf(genesis, order, options)
          this = new genesis

          this.map_wpf_payment order, options
        end

      end

      # Initialize the mapper
      def initialize(context)
        @context = context
      end

      # Map processing 3DSv2 attributes
      def map_processing_payment(order, source, options)
        user_orders = fetch_user_orders order

        method_attributes options
        control_attributes options
        purchase_attributes order
        merchant_risk_attributes order, user_orders
        card_holder_attributes order, user_orders
        browser_attributes source

        self
      end

      # Map WPF 3DSv2 attributes
      def map_wpf_payment(order, options)
        user_orders = fetch_user_orders order

        control_attributes options, is_processing: false
        purchase_attributes order
        merchant_risk_attributes order, user_orders
        card_holder_attributes order, user_orders

        self
      end

      # Map Threeds Method attributes
      def method_attributes(options)
        @context.threeds_v2_method_callback_url =
          "#{options[:hostname]}#{api_v2_storefront_emerchantpay_threeds_callback_handler_path}"

        nil
      end

      def control_attributes(options, is_processing: true)
        if is_processing
          @context.threeds_v2_control_device_type = fetch_threeds_constant 'Control::DeviceTypes::BROWSER'
        end

        @context.threeds_v2_control_challenge_window_size =
          fetch_threeds_constant('Control::ChallengeWindowSizes::FULLSCREEN')
        @context.threeds_v2_control_challenge_indicator   =
          PaymentMethodHelper.select_options_value options, :challenge_indicator

        nil
      end

      # Map 3DSv2 Purchase Category
      def purchase_attributes(order)
        @context.threeds_v2_purchase_category = if order.digital
                                                  fetch_threeds_constant('Purchase::Categories::SERVICE')
                                                else
                                                  fetch_threeds_constant('Purchase::Categories::GOODS')
                                                end

        nil
      end

      # Map 3DSv2 Merchant Risk
      def merchant_risk_attributes(order, user_orders)
        @context.threeds_v2_merchant_risk_shipping_indicator      = fetch_shipping_indicator order
        @context.threeds_v2_merchant_risk_delivery_timeframe      = fetch_delivery_timeframe order
        @context.threeds_v2_merchant_risk_reorder_items_indicator = fetch_reorder_items_indicator order, user_orders

        nil
      end

      # 3DSv2 Card Holder Account attributes
      def card_holder_attributes(order, user_orders) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        if order.user.empty?
          @context.threeds_v2_card_holder_account_registration_indicator =
            fetch_threeds_constant('CardHolderAccount::RegistrationIndicators::GUEST_CHECKOUT')

          return nil
        end

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
        shipping_address_first_used = ThreedsHelper.fetch_shipping_address_first_used order.user.shipping_address
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

        purchases_last6_months = ThreedsHelper.filter_purchases_count_last6_months user_orders
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

      # 3DSv2 Browser attributes
      def browser_attributes(source) # rubocop:disable Metrics/AbcSize
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

      private

      # Helper method for 3DSv2 constants
      def fetch_threeds_constant(constant)
        "#{ThreedsHelper::CONSTANT_PATH}#{constant}".constantize
      end

      # Fetch User Orders
      def fetch_user_orders(order)
        return SpreeOrderRepository.orders_by_user order.user_id if order.user_id

        []
      end

      # Fetch 3DSv2 Merchant Risk Shipping Indicator
      def fetch_shipping_indicator(order)
        return fetch_threeds_constant('MerchantRisk::ShippingIndicators::DIGITAL_GOODS') if order.digital

        if order.shipping_address&.to_s == order.billing_address&.to_s
          return fetch_threeds_constant 'MerchantRisk::ShippingIndicators::SAME_AS_BILLING'
        end

        return fetch_threeds_constant 'MerchantRisk::ShippingIndicators::STORED_ADDRESS' if order.user_id

        fetch_threeds_constant 'MerchantRisk::ShippingIndicators::OTHER'
      end

      # Fetch 3DSv2 Merchant Risk Delivery Timeframe
      def fetch_delivery_timeframe(order)
        return fetch_threeds_constant 'MerchantRisk::DeliveryTimeframes::ELECTRONICS' if order.digital

        fetch_threeds_constant 'MerchantRisk::DeliveryTimeframes::ANOTHER_DAY'
      end

      # Fetch 3DSv2 Merchant Risk Reorder Items Indicator
      def fetch_reorder_items_indicator(order, user_orders)
        return fetch_threeds_constant 'MerchantRisk::ReorderItemIndicators::FIRST_TIME' unless order.user_id

        variants = []
        order.line_items.each { |line_item| variants.push line_item[:variant_id] }

        reordered = SpreeOrderRepository.reordered_variant? order.id, variants, user_orders

        return fetch_threeds_constant 'MerchantRisk::ReorderItemIndicators::REORDERED' if reordered

        fetch_threeds_constant 'MerchantRisk::ReorderItemIndicators::FIRST_TIME'
      end

    end
  end
end

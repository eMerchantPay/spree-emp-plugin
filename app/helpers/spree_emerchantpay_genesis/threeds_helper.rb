module SpreeEmerchantpayGenesis
  # Helper methods used in the 3DSv2 parameters handling
  class ThreedsHelper

    LESS_THAN_30_DAYS_INDICATOR    = 'less_then_30_days'.freeze
    MORE_30_LESS_60_DAYS_INDICATOR = 'more_30_less_60_days_indicator'.freeze
    MORE_THAN_60_DAYS_INDICATOR    = 'more_than_60_days_indicator'.freeze
    CURRENT_TRANSACTION_INDICATOR  = 'current_transaction'.freeze
    DATE_ISO_FORMAT                = GenesisRuby::Api::Constants::DateTimeFormats::YYYY_MM_DD_ISO_8601
    COMPLETED_SPREE_PAYMENT_STATE  = 'completed'.freeze

    class << self

      # 3DSv2 payments for the last 24 hours
      def filter_transaction_activity_24_hours(user_orders)
        one_day_ago = DateTime.now - 1.day

        user_orders.filter { |row| DateTime.parse(row['payment_created_at'].to_s) >= one_day_ago }.count
      end

      # 3DSv2 payments for the previous year
      def filter_transaction_activity_previous_year(user_orders)
        previous_year       = (DateTime.now - 1.year).strftime('%Y')
        previous_year_start = DateTime.parse("#{previous_year}-01-01 00:00:00")
        previous_year_end   = DateTime.parse("#{previous_year}-12-31 23:59:59")

        user_orders.filter do |row|
          payment_created_at = DateTime.parse row['payment_created_at'].to_s

          previous_year_start <= payment_created_at && payment_created_at <= previous_year_end
        end.count
      end

      # 3DSv2 payments for the last 6 months
      def filter_purchases_count_last6_months(user_orders)
        today          = DateTime.now
        six_months_ago = DateTime.now - 6.month

        user_orders.filter do |row|
          payment_created_at = DateTime.parse row['payment_created_at'].to_s

          six_months_ago <= payment_created_at && payment_created_at <= today &&
            row['payment_state'] == COMPLETED_SPREE_PAYMENT_STATE
        end.count
      end

      # 3DSv2 registration date with the 3DSv2 requester
      def filter_first_completed_payment(user_orders)
        filtered = user_orders.filter { |row| row['payment_state'] == COMPLETED_SPREE_PAYMENT_STATE }.first

        return {} unless filtered

        filtered
      end

      # Fetch 3DSv2 Card Holder Shipping Address first used
      def fetch_shipping_address_first_used(shipping_address)
        return DateTime.now.strftime(SpreeEmerchantpayGenesis::ThreedsHelper::DATE_ISO_FORMAT) if shipping_address.nil?

        shipping_address.created_at.strftime(SpreeEmerchantpayGenesis::ThreedsHelper::DATE_ISO_FORMAT)
      end

      # Fetch 3DSv2 Last Change Date by checking the Billing and Shipping Addresses updated_at
      def fetch_last_change_date(billing_address, shipping_address)
        bill_updated = billing_address.nil? ? DateTime.now : billing_address.updated_at
        ship_updated = shipping_address.nil? ? DateTime.now : shipping_address.updated_at

        bill_updated > ship_updated ? bill_updated.strftime(DATE_ISO_FORMAT) : ship_updated.strftime(DATE_ISO_FORMAT)
      end

      # Fetch the given 3DSv2 parameter indicator
      def fetch_class_indicator(indicator_class, updated_at) # rubocop:disable Metrics/MethodLength
        constant_path = 'GenesisRuby::Api::Constants::Transactions::Parameters::Threeds::Version2::CardHolderAccount::'

        case fetch_indicator updated_at
        when LESS_THAN_30_DAYS_INDICATOR
          "#{constant_path}#{indicator_class}::LESS_THAN_30DAYS".constantize
        when MORE_30_LESS_60_DAYS_INDICATOR
          "#{constant_path}#{indicator_class}::FROM_30_TO_60_DAYS".constantize
        when MORE_THAN_60_DAYS_INDICATOR
          "#{constant_path}#{indicator_class}::MORE_THAN_60DAYS".constantize
        else
          if indicator_class == 'PasswordChangeIndicators'
            return "#{constant_path}#{indicator_class}::DURING_TRANSACTION".constantize
          end

          "#{constant_path}#{indicator_class}::CURRENT_TRANSACTION".constantize
        end
      end

      # Validates the payload of the 3DSv2 Callback request signature
      def validate_callback_signature(signature, unique_id, status, merchant_password)
        generated_signature = Digest::SHA512.hexdigest "#{unique_id}#{status}#{merchant_password}"

        signature == generated_signature
      end

      private

      # Fetch indicator by the given date time string
      def fetch_indicator(update_at)
        today    = DateTime.now
        updated  = DateTime.parse(update_at)
        interval = (today - updated).to_i

        return self::LESS_THAN_30_DAYS_INDICATOR if interval.positive? && interval < 30
        return self::MORE_30_LESS_60_DAYS_INDICATOR if interval >= 30 && interval <= 60
        return self::MORE_THAN_60_DAYS_INDICATOR if interval > 60

        self::CURRENT_TRANSACTION_INDICATOR
      end

    end

  end
end

module SpreeEmerchantpayGenesis
  module Mappers
    # Transaction object Mapper
    class Transaction

      CARD_TYPES = [
        GenesisRuby::Api::Constants::Transactions::AUTHORIZE,
        GenesisRuby::Api::Constants::Transactions::AUTHORIZE_3D,
        GenesisRuby::Api::Constants::Transactions::SALE,
        GenesisRuby::Api::Constants::Transactions::SALE_3D
      ].freeze

      REFERENCE_TYPES = [
        GenesisRuby::Api::Constants::Transactions::CAPTURE,
        GenesisRuby::Api::Constants::Transactions::REFUND,
        GenesisRuby::Api::Constants::Transactions::VOID
      ].freeze

      MOBILE_TYPES = [
        GenesisRuby::Api::Constants::Transactions::GOOGLE_PAY,
        GenesisRuby::Api::Constants::Transactions::APPLE_PAY,
        GenesisRuby::Api::Constants::Transactions::PAY_PAL
      ].freeze

      EXCLUDED_TYPES = [
        GenesisRuby::Api::Constants::Transactions::PPRO
      ].freeze

      MOBILE_PAYMENT_SUB_TYPE_AUTHORIZE = 'authorize'.freeze
      MOBILE_PAYMENT_SUB_TYPE_SALE      = 'sale'.freeze
      MOBILE_PAYMENT_SUB_TYPE_EXPRESS   = 'express'.freeze

      # Provide transaction class object from the given type
      def self.for(transaction_type)
        object_class   = nil
        card_type      = CARD_TYPES.detect { |type| type == transaction_type.downcase }
        reference_type = REFERENCE_TYPES.detect { |type| type == transaction_type.downcase }

        return nil if !card_type.nil? && !reference_type.nil?

        object_class = initialize_card_type transaction_type if card_type
        object_class = initialize_reference_type transaction_type if reference_type

        object_class
      end

      # Initialize Card Type
      def self.initialize_card_type(transaction_type)
        "GenesisRuby::Api::Requests::Financial::Cards::#{transaction_type.capitalize}".constantize
      end

      # Initialize Reference Type
      def self.initialize_reference_type(transaction_type)
        "GenesisRuby::Api::Requests::Financial::#{transaction_type.capitalize}".constantize
      end

      # Map Web Payment Form Mobile transaction types
      def self.map_wpf_config_mobile_types(types)
        types.push(*mobile_types_with_payment_sub_types)
      end

      # Provides Mobile payment types|subtypes
      def self.mobile_payment_sub_types
        %W[
          _#{Mappers::Transaction::MOBILE_PAYMENT_SUB_TYPE_AUTHORIZE}
          _#{Mappers::Transaction::MOBILE_PAYMENT_SUB_TYPE_SALE}
          _#{Mappers::Transaction::MOBILE_PAYMENT_SUB_TYPE_EXPRESS}
        ]
      end

      # Provides all Mobile payment types with their subtypes
      def self.mobile_types_with_payment_sub_types
        %W[
          #{GenesisRuby::Api::Constants::Transactions::GOOGLE_PAY}_#{MOBILE_PAYMENT_SUB_TYPE_SALE}
          #{GenesisRuby::Api::Constants::Transactions::GOOGLE_PAY}_#{MOBILE_PAYMENT_SUB_TYPE_AUTHORIZE}
          #{GenesisRuby::Api::Constants::Transactions::APPLE_PAY}_#{MOBILE_PAYMENT_SUB_TYPE_SALE}
          #{GenesisRuby::Api::Constants::Transactions::APPLE_PAY}_#{MOBILE_PAYMENT_SUB_TYPE_AUTHORIZE}
          #{GenesisRuby::Api::Constants::Transactions::PAY_PAL}_#{MOBILE_PAYMENT_SUB_TYPE_SALE}
          #{GenesisRuby::Api::Constants::Transactions::PAY_PAL}_#{MOBILE_PAYMENT_SUB_TYPE_AUTHORIZE}
          #{GenesisRuby::Api::Constants::Transactions::PAY_PAL}_#{MOBILE_PAYMENT_SUB_TYPE_EXPRESS}
        ]
      end

      # Extract mobile type from the sub type and return the WPF custom attribute structure
      def self.extract_mobile_type_with_sub_type(mobile_with_sub_type)
        mobile_type = mobile_with_sub_type.gsub(/#{Mappers::Transaction.mobile_payment_sub_types.join("|")}/, '')

        Hash[mobile_type, Hash[mobile_subtype_key(mobile_type), mobile_with_sub_type.gsub(/#{mobile_type}_/, '')]]
      end

      # Returns the Mobile Sub/Type WFP custom attribute
      def self.mobile_subtype_key(mobile_type)
        google_pay  = GenesisRuby::Api::Constants::Transactions::GOOGLE_PAY
        apple_pay   = GenesisRuby::Api::Constants::Transactions::APPLE_PAY
        pay_pal     = GenesisRuby::Api::Constants::Transactions::PAY_PAL

        case mobile_type
        when google_pay, apple_pay
          'payment_subtype'
        when pay_pal
          'payment_type'
        end
      end

      # Exclude specific transaction types that should not be available in the list
      def self.exclude_wpf_types(types)
        (EXCLUDED_TYPES + MOBILE_TYPES).each { |type| types.delete type }

        types
      end

    end
  end
end

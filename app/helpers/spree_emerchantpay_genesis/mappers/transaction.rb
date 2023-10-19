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

    end
  end
end

module SpreeEmerchantpayGenesis
  module Data
    # User data
    class User < Base::Data

      # Provide formatted Create At
      def created_at_formatted
        self[:created_at].strftime(GenesisRuby::Api::Constants::DateTimeFormats::YYYY_MM_DD_ISO_8601)
      end

      # Provide formatted Updated At
      def updated_at_formatted
        self[:updated_at].strftime(GenesisRuby::Api::Constants::DateTimeFormats::YYYY_MM_DD_ISO_8601)
      end

      # Billing Address object
      def billing_address
        return nil if self[:bill_address_id].nil?

        Spree::Address.find_by(id: self[:bill_address_id])
      end

      # Shipping Address object
      def shipping_address
        return nil if self[:ship_address_id].nil?

        Spree::Address.find_by(id: self[:ship_address_id])
      end

    end
  end
end

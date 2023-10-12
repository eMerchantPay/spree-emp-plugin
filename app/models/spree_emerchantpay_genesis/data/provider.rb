module SpreeEmerchantpayGenesis
  module Data
    # Provider data
    class Provider < Base::Data

      # Predefine Amount accessor (BigDecimal.to_s)
      def amount
        return total.to_s unless total.nil?

        total
      end

      # Override default ip accessor
      # Requests via Spree API causing ip = nil
      def ip
        return '127.0.0.1' if self[:ip].nil?

        self[:ip]
      end

    end
  end
end

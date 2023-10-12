module SpreeEmerchantpayGenesis
  module Data
    # Billing and Shipping Address data
    class Address < Base::Data

      # Override the default zip method behaviour
      def zip
        self[:zip]
      end

      # Split name into first and last names
      def name=(value)
        names = value.nil? ? [] : value.split

        self[:first_name] = names.first
        self[:last_name]  = names.last

        self[:name] = value
      end

    end
  end
end

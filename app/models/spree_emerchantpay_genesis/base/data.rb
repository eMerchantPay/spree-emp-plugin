module SpreeEmerchantpayGenesis
  module Base
    # Simple key value hash object
    # Usage: ConfigurableOptions.<name>=, ConfigurableOptions.<name>
    class Data < Hash

      def []=(key, value)
        super(key.to_sym, value)
      end

      def [](key)
        super(key.to_sym)
      end

      # Dynamic accessors for the hash[keys]
      def method_missing(name, *args)
        name_string = name.to_s
        if name_string.chomp!('=')
          self[name_string] = args.first
        else
          self[name_string]
        end
      end

      # Define ConfigurableOptions.method("<method>") call
      # If we dont have defined hash key we will raise exception
      def respond_to_missing?(name, include_private = false)
        method_missing(name) || super
      end

    end
  end
end

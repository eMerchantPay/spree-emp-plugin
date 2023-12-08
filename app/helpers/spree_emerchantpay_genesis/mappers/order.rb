module SpreeEmerchantpayGenesis
  module Mappers
    # Spree Order Mapper
    class Order

      NESTED_NODES             = %w(billing_address shipping_address line_items user).freeze
      ORDER_ALLOWED_ATTRIBUTES = %w(
        id currency item_total total user_id token item_count email shipment_total
        bill_address_id ship_address_id last_ip_address adjustment_total additional_tax_total included_tax_total number
        customer ip order_id shipping tax subtotal discount name address1 address2 city
        state zip country phone digital
        created_at updated_at
      ) + NESTED_NODES

      # Provider Data
      def self.for(raw_data)
        mapped_data = new SpreeEmerchantpayGenesis::Data::Provider.new

        mapped_data.map raw_data
      end

      def initialize(data)
        @data = data
      end

      def map(order)
        @data = map_order_data @data, order
      end

      private

      def map_order_data(data, raw_data)
        raw_data.each do |attr_key, attr_value|
          next unless ORDER_ALLOWED_ATTRIBUTES.include? attr_key.to_s

          node_key = "#{attr_key}="
          data.public_send(node_key, attr_value)

          if attr_value.is_a?(Hash) && NESTED_NODES.include?(attr_key.to_s)
            map_user data, node_key, attr_value if attr_key.to_s == 'user'
            map_address data, node_key, attr_value if %w(billing_address shipping_address).include? attr_key.to_s
          end
        end

        data
      end

      # Map User
      def map_user(data, node_key, attr_value)
        data.public_send node_key, map_order_data(SpreeEmerchantpayGenesis::Data::User.new, attr_value)
      end

      # Map Addresses
      def map_address(data, node_key, attr_value)
        data.public_send node_key, map_order_data(SpreeEmerchantpayGenesis::Data::Address.new, attr_value)
      end

    end
  end
end

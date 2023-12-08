module SpreeEmerchantpayGenesis
  # Spree Order Repository
  class SpreeOrderRepository

    class << self

      # Find Order by its number
      def find_by_number(order_number)
        Spree::Order.find_by(number: order_number)
      end

      # Retrieve all order ids and their products that belong to user_id
      def orders_by_user(user_id, type = 'Spree::Gateway::EmerchantpayDirect') # rubocop:disable Metrics/MethodLength
        ActiveRecord::Base.connection.execute(
          "SELECT o.id as order_id, \
                  o.ship_address_id as order_shipping_address, \
                  o.created_at as order_created_at, \
                  o.state as order_state, \
                  l.variant_id as variant_id, \
                  p.id as payment_id, \
                  p.state as payment_state, \
                  p.created_at as payment_created_at \
          FROM spree_orders as o \
          INNER JOIN spree_payments as p on (p.order_id = o.id) \
          INNER JOIN spree_payment_methods as m on (m.id = p.payment_method_id) \
          INNER JOIN spree_line_items as l on (l.order_id = o.id) \
          WHERE m.type = '#{type}' AND o.user_id = '#{user_id}' \
          ORDER BY o.id ASC"
        )
      end

      # Loop through the orders_by_user result and check if the given variant_ids exists
      def reordered_variant?(exclude_oder_id, variant_ids, user_orders)
        reordered = false

        user_orders.each do |order|
          next if order['order_id'] == exclude_oder_id

          if variant_ids.include? order['variant_id']
            reordered = true
            break
          end
        end

        reordered
      end

    end

  end
end

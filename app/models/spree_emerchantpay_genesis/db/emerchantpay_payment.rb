module SpreeEmerchantpayGenesis
  module Db
    # EmerchantpayPayments DB model
    class EmerchantpayPayment < ApplicationRecord

      DATE_TIME_FORMAT = '%Y-%m-%d %H:%M'.freeze

      store :request, coder: JSON
      store :response, coder: JSON

      # Get amount formatted in major currency
      def formatted_amount
        GenesisRuby::Utils::MoneyFormat.exponent_to_amount amount, currency
      end

      # Get created_at formatted
      def formatted_created_at
        created_at.strftime DATE_TIME_FORMAT
      end

      # Get updated_at formatted
      def formatted_updated_at
        updated_at.strftime DATE_TIME_FORMAT
      end

    end
  end
end

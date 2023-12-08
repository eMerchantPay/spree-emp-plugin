require 'spree/gateway/emerchantpay_direct'

module SpreeEmerchantpayGenesis
  module Notifications
    # Notification Handler Service
    class ServiceHandler < Base::PaymentService

      attr_reader :genesis_notification

      class << self

        def call(params)
          handler = new params

          handler.genesis_notification
        end

      end

      def initialize(params)
        super params

        @genesis_notification = process_notification
      end

      # Validate the notification data and execute reconcile
      def process_notification
        @genesis_provider.notification @emerchantpay_payment, params
      end

    end
  end
end

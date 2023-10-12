module Spree
  # Spree Payment Decorator
  module PaymentDecorator

    # Query all Genesis Gateway Payments
    def emerchantpay_payments
      SpreeEmerchantpayGenesis::EmerchantpayPaymentsRepository.find_all_by_order_and_payment order.number, number
    end

  end
end

::Spree::Payment.prepend(Spree::PaymentDecorator)

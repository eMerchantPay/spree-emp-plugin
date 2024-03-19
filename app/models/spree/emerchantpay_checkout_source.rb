module Spree
  # Emerchantpay Checkout Source
  class EmerchantpayCheckoutSource < Spree::Base

    acts_as_paranoid

    self.table_name = 'emerchantpay_checkout_sources'

    belongs_to :payment_method
    belongs_to :user, class_name: Spree.user_class.to_s, foreign_key: 'user_id',
               optional: true
    has_many :payments, as: :source

    include Spree::Metadata

    def actions
      %w(capture void credit)
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      payment.pending? || payment.checkout?
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      !payment.failed? && !payment.void?
    end

    # Indicates whether its possible to credit the payment.  Note that most gateways require that the
    # payment be settled first which generally happens within 12-24 hours of the transaction.
    def can_credit?(payment)
      payment.completed? && payment.credit_allowed.positive?
    end

  end
end

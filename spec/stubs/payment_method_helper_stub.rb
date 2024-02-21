module SpreeEmerchantpayGenesisSpec
  module Stubs
    # Payment Method Helper Stub
    class PaymentMethodHelperStub

      include Spree::Admin::BaseHelper
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::FormOptionsHelper
      include Spree::Admin::PaymentMethodsHelper

      attr_accessor :output_buffer

    end
  end
end

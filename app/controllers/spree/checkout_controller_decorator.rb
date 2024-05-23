module Spree
  module CheckoutControllerDecorator

    # Updates the order and advances to the next state (when possible.)
    def update
      result = process_emp_direct_payment? ? process_emp_direct_payment : default_payment_processing

      if result
        @order.temporary_address = !params[:save_user_address]

        order_next

        process_completed_order && return if @order.completed?

        redirect_to spree.checkout_state_path @order.state
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    # Default Rails FrontEnd Checkout controller `update` logic
    def default_payment_processing
      @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
    end

    # Proceed with Spree Order current state execution and move to the next
    def order_next
      return if @order.next

      flash[:error] = @order.errors.full_messages.join("\n")
    end

    # Get payment_method_id from the params
    def payment_method_id
      params[:order][:payments_attributes].last[:payment_method_id].presence
    rescue NoMethodError
      nil
    end

    # Handle completed order
    def process_completed_order
      redirect_url             = nil
      @current_order           = nil
      flash['order_completed'] = true

      redirect_url = @order.payments.last.private_metadata['redirect_url'] if @order.payments.last.private_metadata

      redirect_to redirect_url || completion_route, allow_other_host: true
    end

    # Check for Emerchantpay Direct Payment process
    def process_emp_direct_payment?
      @order.state == 'payment' && emerchantpay_direct_payment?
    end

    # Check if the current payment method is Emerchantpay Direct
    def emerchantpay_direct_payment?
      return false unless payment_method_id

      payment_method = Spree::PaymentMethod.find(payment_method_id)

      payment_method&.type == Spree::Gateway::EmerchantpayDirect.name
    end

    # Process Emerchantpay Direct Payment
    def process_emp_direct_payment
      result = create_payment_service.call(
        order: @order,
        params: {
          payment_method_id: payment_method_id,
          source_attributes: params[:payment_source][payment_method_id.to_s.to_sym].presence
        }
      )

      result.success?
    end

    # Spree Storefront Create Payment Service
    def create_payment_service
      Spree::Api::Dependencies.storefront_payment_create_service.constantize
    end

  end
end

Spree::CheckoutController.prepend(Spree::CheckoutControllerDecorator)

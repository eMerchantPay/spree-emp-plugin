module Spree
  # 3DSv2 Secure Method Continue customer controller
  class EmerchantpayThreedsController < ApplicationController

    after_action :allow_iframe, only: :index

    layout 'spree/method_continue'

    def index
      service = SpreeEmerchantpayGenesis::Threeds::MethodContinue.call permitted_params

      render 'method_continue', locals: service.build_secure_method_params
    rescue StandardError => e
      Rails.logger.error = "Emerchantpay Threeds Controller: #{e.message}"

      render plain: 'Error during Emerchantpay 3DSv2 execution. Contact administrator!'
    end

    private

    # Allow iFrame execution
    def allow_iframe
      response.headers.except! 'X-Frame-Options'
    end

    def permitted_params
      params.permit :unique_id, :checksum
    end

  end
end

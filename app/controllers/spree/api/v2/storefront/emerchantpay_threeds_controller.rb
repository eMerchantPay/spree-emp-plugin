module Spree
  module Api
    module V2
      module Storefront
        # 3D Secure Helper methods
        class EmerchantpayThreedsController < ::Spree::Api::V2::BaseController

          before_action :validate_params, except: [:callback_status]
          before_action :initialize_service
          after_action :allow_iframe, only: :callback_handler

          attr_reader :permitted_params

          # 3DSv2 Callback webhook handler
          def callback_handler
            @service.store_callback_status

            render status: 200, json: { status: @service.fetch_callback_status }
          end

          # 3DSv2 Callback webhook status
          def callback_status
            render status: 200, json: { status: @service.fetch_callback_status }
          end

          # 3DSv2 Secure Method Continue Request
          def method_continue
            render status: 200, json: { status: 'OK', redirect_url: @service.process_method_continue }
          end

          private

          # Initialize 3DSv2 Callback Service
          def initialize_service
            process_params

            @service = SpreeEmerchantpayGenesis::Threeds::Callback.call @permitted_params
          rescue StandardError
            render status: 422, json: { error: 'Given request is invalid!' }
          end

          # Permit params
          def process_params
            @permitted_params = params.permit :unique_id, :signature, :threeds_method_status
          end

          # Validate Params
          def validate_params
            params.require [:unique_id, :signature]
          end

          # Allow iFrame execution
          def allow_iframe
            response.headers.except! 'X-Frame-Options'
          end

        end
      end
    end
  end
end

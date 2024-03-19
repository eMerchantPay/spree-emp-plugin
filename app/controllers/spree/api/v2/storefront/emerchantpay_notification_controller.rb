module Spree
  module Api
    module V2
      module Storefront
        # Emerchantpay IPN Controller handler
        class EmerchantpayNotificationController < ::Spree::Api::V2::BaseController

          before_action :validate_params

          attr_reader :permitted_params

          # Notification handler action
          def index
            process_params

            notification = SpreeEmerchantpayGenesis::Notifications::ServiceHandler.call permitted_params

            render xml: notification.generate_response
          rescue StandardError => e
            render status: 422, plain: "Spree notification handling exited with: #{e.message}"
          end

          private

          # Validate params
          def validate_params
            params.require [:signature]
          end

          # Permit params
          def process_params # rubocop:disable Metrics/MethodLength
            @permitted_params = params.permit(
              :transaction_id, :terminal_token, :unique_id, :transaction_type, :status, :signature, :amount,
              :eci, :cvv_result_code, :retrieval_reference_number, :authorization_code, :scheme_transaction_identifier,
              :scheme_settlement_date, :threeds_authentication_flow, :threeds_target_protocol_version,
              :threeds_concrete_protocol_version, :threeds_method_status, :scheme_response_code, :avs_response_code,
              :avs_response_text, :reference_transaction_unique_id, :threeds_authentication_status_reason_code,
              :card_brand, :card_number, :card_type, :card_subtype, :card_issuing_bank, :card_holder, :expiration_year,
              :expiration_month, :wpf_unique_id, :payment_transaction_terminal_token, :payment_transaction_unique_id,
              :payment_transaction_transaction_type, :payment_transaction_amount, :wpf_status, :wpf_transaction_id,
              :notification_type
            )
          end

        end
      end
    end
  end
end

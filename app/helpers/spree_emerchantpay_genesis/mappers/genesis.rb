require 'securerandom'

module SpreeEmerchantpayGenesis
  module Mappers
    # Genesis Gateway Data Mapper
    class Genesis

      TRANSACTION_ID_PREFIX = 'sp-'.freeze

      attr_reader :genesis_request

      # Provider Data
      def self.for(genesis, provider, source, options)
        this = new genesis

        this.map provider, source, options
      end

      def initialize(genesis_request)
        @genesis_request = genesis_request
      end

      def map(provider, source, options)
        common_attributes provider
        credit_card_attributes source
        billing_attributes provider
        shipping_attributes provider
        asyn_attributes options if asyn?

        self
      end

      private

      # Common Genesis Attributes
      def common_attributes(provider) # rubocop:disable Metrics/AbcSize
        @genesis_request.transaction_id = generate_transaction_id
        @genesis_request.amount         = provider.total.to_s
        @genesis_request.currency       = provider.currency
        @genesis_request.usage          = I18n.t 'usage', scope: 'emerchantpay.payment'
        @genesis_request.customer_email = provider.email
        @genesis_request.customer_phone = provider.billing_address&.phone
        @genesis_request.remote_ip      = provider.ip
      end

      # Credit Card Attributes
      def credit_card_attributes(source)
        @genesis_request.card_holder      = source.name
        @genesis_request.card_number      = source.number
        @genesis_request.expiration_month = source.month
        @genesis_request.expiration_year  = source.year
        @genesis_request.cvv              = source.verification_value
      end

      # Billing Attributes
      def billing_attributes(provider) # rubocop:disable Metrics/AbcSize
        @genesis_request.billing_first_name = provider.billing_address.first_name
        @genesis_request.billing_last_name  = provider.billing_address.last_name
        @genesis_request.billing_address1   = provider.billing_address.address1
        @genesis_request.billing_address2   = provider.billing_address.address2
        @genesis_request.billing_zip_code   = provider.billing_address.zip
        @genesis_request.billing_city       = provider.billing_address.city
        @genesis_request.billing_state      = provider.billing_address.state
        @genesis_request.billing_country    = provider.billing_address.country
      end

      # Shipping Attributes
      def shipping_attributes(provider) # rubocop:disable Metrics/AbcSize
        @genesis_request.shipping_first_name = provider.shipping_address.first_name
        @genesis_request.shipping_last_name  = provider.shipping_address.last_name
        @genesis_request.shipping_address1   = provider.shipping_address.address1
        @genesis_request.shipping_address2   = provider.shipping_address.address2
        @genesis_request.shipping_zip_code   = provider.shipping_address.zip
        @genesis_request.shipping_city       = provider.shipping_address.city
        @genesis_request.shipping_state      = provider.shipping_address.state
        @genesis_request.shipping_country    = provider.shipping_address.country
      end

      def asyn_attributes(options)
        @genesis_request.notification_url   = 'https://example.com' # TODO: add IPN url
        @genesis_request.return_success_url = options[:return_success_url]
        @genesis_request.return_failure_url = options[:return_failure_url]
      end

      # Generate Transaction Id
      def generate_transaction_id
        "#{TRANSACTION_ID_PREFIX}#{SecureRandom.uuid[TRANSACTION_ID_PREFIX.length..]}"[0..32].downcase
      end

      # Checks if the given request is asynchronous or not
      def asyn?
        @genesis_request.instance_of?(GenesisRuby::Api::Requests::Financial::Cards::Authorize3d) ||
          @genesis_request.instance_of?(GenesisRuby::Api::Requests::Financial::Cards::Sale3d)
      end

    end
  end
end

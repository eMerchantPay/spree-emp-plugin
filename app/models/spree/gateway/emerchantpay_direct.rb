module Spree
  # Emerchantpay Direct Payment Method
  class Gateway::EmerchantpayDirect < SpreeEmerchantpayGenesis::Base::Gateway # rubocop:disable Style/ClassAndModuleChildren

    preference :token, :string

    delegate :load_data, :load_source, :load_payment, to: :provider

    def method_type
      'emerchantpay_direct'
    end

    def provider_class
      SpreeEmerchantpayGenesis::GenesisProvider
    end

    def provider
      @provider = provider_class.new options if @provider.nil?

      @provider
    end

    def purchase(_money_in_cents, source, gateway_options) # rubocop:disable Metrics/MethodLength
      order, payment = order_data_from_options gateway_options
      user           = order.user

      prepare_provider(
        order.attributes.symbolize_keys.merge(
          gateway_options,
          { digital: order.digital? },
          { line_items: order.line_items.map { |line_item| line_item.attributes.symbolize_keys } },
          { user: (user ? user.attributes.symbolize_keys : {}) }
        ),
        source,
        payment
      )

      provider.purchase
    end

    def authorize(money_in_cents, source, gateway_options)
      purchase money_in_cents, source, gateway_options
    end

    def supports?(_source)
      true
    end

    def source_required?
      true
    end

    def payment_source_class
      CreditCard
    end

    def auto_capture?
      !GenesisRuby::Utils::Transactions::References::CapturableTypes.all.include? options[:transaction_types]
    end

    private

    # Prepare provider
    def prepare_provider(data, source, payment)
      load_data SpreeEmerchantpayGenesis::Mappers::Order.for data
      load_source source
      load_payment payment
    end

  end
end

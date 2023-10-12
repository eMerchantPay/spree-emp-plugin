module SpreeEmerchantpayGenesis
  # Engine
  class Engine < ::Rails::Engine

    require 'spree/core'
    require 'genesis_ruby'

    isolate_namespace Spree
    engine_name 'spree_emerchantpay_genesis'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

    config.after_initialize do |app|
      app.config.spree.payment_methods += [
        Spree::Gateway::EmerchantpayDirect
      ]
    end

  end
end

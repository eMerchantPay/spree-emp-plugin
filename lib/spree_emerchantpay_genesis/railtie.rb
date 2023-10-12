require 'rails/railtie'

module SpreeEmerchantpayGenesis
  # Initialize Rails Railtie hooks
  class Railtie < Rails::Railtie

    rake_tasks do
      load 'tasks/spree_emerchantpay_genesis_tasks.rake'
    end

  end
end

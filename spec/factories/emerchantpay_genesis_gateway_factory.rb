FactoryBot.define do
  factory :genesis do
    transient do
      config do
        config          = GenesisRuby::Configuration.new
        config.endpoint = GenesisRuby::Api::Constants::Endpoints::EMERCHANTPAY
        config.token    = Faker::Internet.uuid

        config
      end
    end
  end

  factory :genesis_authorize3d,
          parent: :genesis,
          class: 'GenesisRuby::Api::Requests::Financial::Cards::Authorize3d' do

    initialize_with { new config }
  end

  factory :genesis_sale3d,
          parent: :genesis,
          class: 'GenesisRuby::Api::Requests::Financial::Cards::Authorize3d' do

    initialize_with { new config }
  end

  factory :genesis_capture,
          parent: :genesis,
          class: 'GenesisRuby::Api::Requests::Financial::Capture' do

    initialize_with { new config }
  end

  factory :genesis_method_continue,
          parent: :genesis,
          class: 'GenesisRuby::Api::Requests::Financial::Cards::Threeds::V2::MethodContinue' do

    initialize_with { new config }
  end
end

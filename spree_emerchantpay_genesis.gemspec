lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_emerchantpay_genesis/version'

Gem::Specification.new do |spec|
  spec.platform              = Gem::Platform::RUBY
  spec.name                  = 'spree_emerchantpay_genesis'
  spec.version               = SpreeEmerchantpayGenesis::VERSION
  spec.summary               = 'emerchantpay Gateway Module for Spree'
  spec.description           = 'This is a Payment Module for Spree that gives you the ability to process payments ' \
    'through emerchantpay\'s Payment Gateway - Genesis.'
  spec.required_ruby_version = '>= 2.7.0'

  spec.author   = 'emerchantpay ltd.'
  spec.email    = ['client_integrations@emerchantpay.com']
  spec.homepage = 'https://emerchantpay.com'
  spec.license  = 'MIT'

  spec.require_path = 'lib'
  spec.requirements << 'none'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/emerchantpay/spree-emp-plugin'
  spec.metadata['changelog_uri'] = 'https://github.com/emerchantpay/spree-emp-plugin/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://github.com/emerchantpay/spree-emp-plugin/blob/main/README.md'

  spec.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md', 'CHANGELOG.md']

  spec.add_dependency 'genesis_ruby', '0.1.3'
  spec.add_dependency 'rails', '~> 6.1.4'
  spec.add_dependency 'securerandom', '~> 0.2.2'
  spec.add_dependency 'spree_backend', '~> 4.4', '>= 4.4.0'
  spec.add_dependency 'spree_core', '~> 4.4', '>= 4.4.0'
  spec.add_dependency 'spree_extension', '0.1.0'

  spec.add_development_dependency 'factory_bot', '~> 4.7'
  spec.add_development_dependency 'faraday-retry', '~> 2.0'
  spec.add_development_dependency 'pronto', '~> 0.11'
  spec.add_development_dependency 'pronto-rubocop', '~> 0.11'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rspec-rails', '~> 6.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.13'
end

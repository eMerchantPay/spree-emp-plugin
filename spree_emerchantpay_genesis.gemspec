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
  spec.metadata['changelog_uri'] = 'https://github.com/emerchantpay/spree-emp-plugin/blob/master/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://github.com/emerchantpay/spree-emp-plugin/blob/master/README.md'

  spec.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md', 'CHANGELOG.md']

  spec.add_dependency 'genesis_ruby', '0.1.7'
  spec.add_dependency 'securerandom', '~> 0.3'
  spec.add_dependency 'spree_backend', '~> 4.4', '>= 4.4.0'
  spec.add_dependency 'spree_core', '~> 4.4', '>= 4.4.0'
  spec.add_dependency 'spree_extension', '~> 0.1'

  spec.add_development_dependency 'appraisal', '~> 2.5'
  spec.add_development_dependency 'database_cleaner', '~> 2.0'
  spec.add_development_dependency 'factory_bot', '~> 4.7'
  spec.add_development_dependency 'faker', '~> 3.2'
  spec.add_development_dependency 'faraday-retry', '~> 2.0'
  spec.add_development_dependency 'ffaker', '~> 2.23'
  spec.add_development_dependency 'pronto', '~> 0.11'
  spec.add_development_dependency 'pronto-rubocop', '~> 0.11'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.6'
  spec.add_development_dependency 'rspec-rails', '~> 6.1'
  spec.add_development_dependency 'rubocop', '~> 1.65'
  spec.add_development_dependency 'rubocop-factory_bot', '~> 2.26'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'vcr', '~> 6.2'
end

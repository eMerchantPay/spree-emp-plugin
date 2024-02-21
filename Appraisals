appraise 'spree-4.4' do
  group :development, :test do
    gem 'spree', '~> 4.4'
    gem 'spree_backend', '~> 4.4'
    gem 'pg'
    gem 'rails-controller-testing'
    gem 'redis', '~> 4.0'
    gem 'spree_auth_devise'
    gem 'webmock', '>= 2.3.1'
  end
end

appraise 'spree-master' do
  group :development, :test do
    gem 'spree', github: 'spree/spree', branch: 'main'
    gem 'spree_backend', github: 'spree/spree_backend', branch: 'main'
    gem 'pg'
    gem 'rails-controller-testing'
    gem 'redis', '~> 4.0'
    gem 'spree_auth_devise'
    gem 'webmock', '>= 2.3.1'
  end
end

#!/bin/bash -e

USERS_TABLE=$(psql -U "${POSTGRES_USER}" -h "${PGHOST}" "${POSTGRES_DB}" -AXqtc "SELECT count(table_name) FROM information_schema.tables WHERE table_schema LIKE 'public' AND table_type LIKE 'BASE TABLE' AND table_name = 'spree_users'")
# First startup
if [ "${USERS_TABLE}" -eq 0 ]; then
  cd /mnt/spree/

  bundle install

  echo "Run Migrations"
  bundle exec rake railties:install:migrations
  bundle exec rake db:prepare

  echo "Install Spree Commerce"
  printf "%s\n%s\n" "$SPREE_ADMIN_USER" "$SPREE_ADMIN_PASS" | bin/rails g spree:install

  echo "Install Spree Commerce dependencies"
  bin/rails g spree:auth:install
  bin/rails g spree:backend:install
  bin/rails g spree:frontend:install

  echo "Prepare assets"
  bin/rails javascript:install:esbuild
  bin/rails turbo:install

  echo "Install emerchantpay Gateway Module for Spree Commerce"
  bin/rails g spree_emerchantpay_genesis:install --auto-run-migrations

  echo "Precompile assets"
  bundle exec rake assets:clean assets:precompile

  echo "Load Spree Commerce Simple Data"
  bundle exec rake spree_sample:load
fi

CHECKOUT_METHOD=$(psql -U "${POSTGRES_USER}" -h "${PGHOST}" "${POSTGRES_DB}" -AXqtc "SELECT count(id) FROM spree_payment_methods where type='Spree::Gateway::EmerchantpayCheckout';")
if [ "${CHECKOUT_METHOD}" -eq 0 ]; then
  echo "Install emerchantpay Checkout Payment Method"
  sh /bin/install_checkout_method.sh
fi

DIRECT_METHOD=$(psql -U "${POSTGRES_USER}" -h "${PGHOST}" "${POSTGRES_DB}" -AXqtc "SELECT count(id) FROM spree_payment_methods where type='Spree::Gateway::EmerchantpayDirect';")
if [ "${DIRECT_METHOD}" -eq 0 ]; then
  echo "Install emerchantpay Direct Payment Method"
  sh /bin/install_direct_method.sh
fi

if [ "${USERS_TABLE}" -eq 1 ]; then
  echo "Keep Migrations up to date"
  cd /mnt/spree
  bundle install
  bundle exec rake railties:install:migrations
  bundle exec rake db:prepare
fi

exec "${@}"

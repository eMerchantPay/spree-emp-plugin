#!/bin/sh -e

DIRECT_ID=$(psql -U "${POSTGRES_USER}" -h "${PGHOST}" "${POSTGRES_DB}" -AXqtc "select nextval(pg_get_serial_sequence('spree_payment_methods', 'id')) as new_id;")

DIRECT_PREFERENCES=$(
cat <<PREF
---
:transaction_types: sale
:token: ${GATEWAY_TOKEN}
:username: ${GATEWAY_USER}
:password: ${GATEWAY_PASS}
:return_success_url: ${SPREE_COMMERCE_ENDPOINT}/orders/|:ORDER:|
:test_mode: true
:return_failure_url: ${SPREE_COMMERCE_ENDPOINT}/checkout/payment?order_number=|:ORDER:|
:threeds_allowed: true
:challenge_indicator: no_preference
:hostname: ${SPREE_COMMERCE_ENDPOINT}
:server: test
PREF
)

DIRECT_METHOD=$(
cat <<SQL
INSERT INTO spree_payment_methods (
  id,
  type,
  name,
  description,
  active,
  deleted_at,
  created_at,
  updated_at,
  display_on,
  auto_capture,
  preferences,
  "position",
  public_metadata,
  private_metadata,
  settings
) VALUES (
  ${DIRECT_ID},
  'Spree::Gateway::EmerchantpayDirect',
  'emerchantpay Direct',
  'emerchantpay Direct',
  true,
  NULL,
  NOW(),
  NOW(),
  'both',
  NULL,
  '${DIRECT_PREFERENCES}',
  4,
  NULL,
  NULL,
  NULL
);
INSERT INTO spree_payment_methods_stores (payment_method_id, store_id) VALUES (${DIRECT_ID}, 1);
SQL
)

psql -U "${POSTGRES_USER}" -h "${PGHOST}" "${POSTGRES_DB}" -c "${DIRECT_METHOD}"

#!/bin/sh -e

CHECKOUT_ID=$(psql -U "${POSTGRES_USER}" -h "${PGHOST}" "${POSTGRES_DB}" -AXqtc "select nextval(pg_get_serial_sequence('spree_payment_methods', 'id')) as new_id;")

CHECKOUT_PREFERENCE=$(
cat <<PREF
---
:transaction_types:
- sale3d
:return_cancel_url: ${SPREE_COMMERCE_ENDPOINT}/checkout/payment
:return_pending_url: ${SPREE_COMMERCE_ENDPOINT}/orders/|:ORDER:|
:language: en
:username: ${GATEWAY_USER}
:password: ${GATEWAY_PASS}
:return_success_url: ${SPREE_COMMERCE_ENDPOINT}/orders/|:ORDER:|
:test_mode: true
:return_failure_url: ${SPREE_COMMERCE_ENDPOINT}/checkout/payment?order_number=|:ORDER:|
:threeds_allowed: true
:challenge_indicator: no_preference
:hostname: ${SPREE_COMMERCE_ENDPOINT}/
:server: test
PREF
)

CHECKOUT_METHOD=$(
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
  ${CHECKOUT_ID},
  'Spree::Gateway::EmerchantpayCheckout',
  'emerchantpay Checkout',
  'emerchantpay Checkout',
  true,
  NULL,
  NOW(),
  NOW(),
  'both',
  NULL,
  '${CHECKOUT_PREFERENCE}',
  3,
  NULL,
  NULL,
  NULL
);
INSERT INTO spree_payment_methods_stores (payment_method_id, store_id) VALUES (${CHECKOUT_ID}, 1);
SQL
)

psql -U "${POSTGRES_USER}" -h "${PGHOST}" "${POSTGRES_DB}" -c "${CHECKOUT_METHOD}"

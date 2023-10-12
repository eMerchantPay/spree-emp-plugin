# emerchantpay Genesis Gateway for Spree
This is a Payment Module for Spree eCommerce that gives you the ability to process payments through emerchantpay's Payment Gateway - Genesis.

# Requirements
* Spree Core 4.x (Tested up to 4.4.0)
* Spree Backend 4.x (Tested up to 4.4.0)
* Spree FrontEnd - Optional (Tested up to 4.4.0)
* Ruby >= 2.7
* Ruby on Rails >= 6.1.4
* [GenesisRuby v0.1.1](https://github.com/GenesisGateway/genesis_ruby/releases/tag/0.1.1)
* PCI-certified server in order to use emerchantpay Direct

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'spree_emerchantpay_genesis'
```

And then execute:
```bash
bundle
```

Or install it yourself as:
```bash
gem install spree_emerchantpay_genesis
```

Copy & run migrations
```bash
bundle exec rails g spree_emerchantpay_genesis:install
```

Restart your server

# Usage

## Spree Storefront API V2

1. Create Cart

```bash
curl --request 'POST' \
  --url 'http://127.0.0.1:4000/api/v2/storefront/cart'
```

Response:

```text
{
  "data":{
    "id":"59",
    "type":"cart",
    "attributes":{
      "number":"R702094375",
      ...
      "currency":"USD",
      "state":"cart",
      "token":"EsDjq1oXEgKI6kuujgfvFw1694531383712",
      ...
    },
    ...
  }
}
```

2. Add Items
<details>
<summary>List Products</summary>

```bash
curl --request 'GET' \
  --url 'https://demo.spreecommerce.org/api/v2/storefront/products' \
  --header 'Accept: application/vnd.api+json'
```

</details>

```bash
curl --request 'POST' \
 --url 'http://localhost:4000/api/v2/storefront/cart/add_item' \
 --header 'Accept: application/vnd.api+json' \
 --header 'X-Spree-Order-Token: EsDjq1oXEgKI6kuujgfvFw1694531383712' \
 --header 'Content-Type: application/vnd.api+json' \
 --data '{
   "variant_id": "130",
   "quantity": "1"
 }'
```

3. Add Shipping
<details>
<summary>List Shipping Rates</summary>

```bash
curl --request 'GET' \
  --url 'https://demo.spreecommerce.org/api/v2/storefront/checkout/shipping_rates' \
  --header 'Accept: application/vnd.api+json' \
  --header 'X-Spree-Order-Token: EsDjq1oXEgKI6kuujgfvFw1694531383712'
```

</details>

```bash
curl --request 'PATCH' \
 --url 'http://localhost:4000/api/v2/storefront/checkout/select_shipping_method' \
 --header 'Accept: application/vnd.api+json' \
 --header 'X-Spree-Order-Token:  EsDjq1oXEgKI6kuujgfvFw1694531383712' \
 --header 'Content-Type: application/vnd.api+json' \
 --data '{
   "shipping_method_id": "1"
 }'
```

4. Update Order
```bash
curl --request 'PATCH' \
  --header 'Accept: application/vnd.api+json' \
  --header 'X-Spree-Order-Token: EsDjq1oXEgKI6kuujgfvFw1694531383712' \
  --header 'Content-Type: application/vnd.api+json' \
  --url 'http://localhost:4000/api/v2/storefront/checkout' \
  --data '{
  "order": {
    "email": "john.smith@example.com",
    "bill_address_attributes": {
      "firstname": "John",
      "lastname": "Smith",
      "address1": "1 Area",
      "city": "Louisville",
      "phone": "01234567891",
      "zipcode": "40202",
      "country_iso": "US",
      "state_id": 500
    },
    "ship_address_attributes": {
      "firstname": "John",
      "lastname": "Smith",
      "address1": "1 Area",
      "city": "Louisville",
      "phone": "01234567891",
      "zipcode": "40202",
      "country_iso": "US",
      "state_id": 500
    },
    "payments_attributes":[
      {
        "payment_method_id":"5"
      }
    ]
  },
  "payment_source": {
    "5": {
      "name": "John Smith",
      "number": "4200000000000000",
      "month": 1,
      "year": 2040,
      "verification_value": "123",
      "cc_type": "visa"
    }
  }
}'
```
5. Create Payment
**CAUTION** Create Payment endpoint will Complete the order! Call this endpoint in order to finish the order!

```bash
curl --request 'POST' \
  --header 'Accept: application/vnd.api+json' \
  --header 'X-Spree-Order-Token: EsDjq1oXEgKI6kuujgfvFw1694531383712' \
  --header 'Content-Type: application/vnd.api+json' \
  --url 'http://localhost:4000/api/v2/storefront/checkout/create_payment' \
  --data '{
  "payment_method_id": "5",
  "source_attributes": {
    "name": "John Smith",
    "number": "4200000000000000",
    "month": 1,
    "year": 2040,
    "verification_value": "123",
    "cc_type": "visa"
  }
}'
```

Response:
**CAUTION** If a redirect URL exists in the response object you MUST redirect the customer for payment completion

```json
{
  "data": {
    "id": "XXX",
    "type": "cart",
    "attributes": {...},
    "relationships": {...},
    "redirect_url": "<customer-redirect-url>"
  }
}
```

## Contributing
Contribution directions go here.

## Development

### Running Specs

`rake test`

### Running Linters

`rake styles`

## License
The gem is available as open source under the terms of the [GPL-2.0 License](https://opensource.org/license/gpl-2-0/).

# emerchantpay Genesis Gateway for Spree
This is a Payment Module for Spree eCommerce that gives you the ability to process payments through emerchantpay's Payment Gateway - Genesis.

# Requirements
* Spree Core 4.x (Tested up to 4.4.0)
* Spree Backend 4.x (Tested up to 4.4.0)
* Spree FrontEnd - Optional (Tested up to 4.4.0)
* Ruby >= 2.7
* Ruby on Rails >= 6.1.4
* [GenesisRuby v0.1.3](https://github.com/GenesisGateway/genesis_ruby/releases/tag/0.1.3)
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

## Create Payment Method
* Sign in to Spree Admin BackEnd
* Navigate to Configurations -> Payment Methods -> New Payment Method
* For Provider `Choose Spree::Gateway::Emerchantpay*`
* Fill in Name, Description and Stores
* Click Create

# Usage

## Configuration
* Navigate to the `Spree::Gateway::Emerchantpay*` payment method in the Configurations
* Fill in Username, Password and Token
* Fill in `hostname` used for the generation of the notification webhook. In most cases, the hostname should be the hostname of the Spree backend.
* Fill in `return_success_url` and `return_failure_url`. Those endpoints will be returned to the `create_payment` response
  * If you add `|:ORDER:|` pattern in the URLs. The pattern will be replaced with the Spree Order Number

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
Accept Header, Java Enabled, Language, Color Depth, Screen height, Screen Width, Time Zone Offset, User Agent parameters must be retrieved from the customer browser. More info [here](https://emerchantpay.github.io/gateway-api-docs/?shell#3ds-v2-request-params).

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
    "cc_type": "visa",
    "accept_header": "*/*",
    "java_enabled": "true",
    "language": "en-GB",
    "color_depth": "32",
    "screen_height": "400",
    "screen_width": "400",
    "time_zone_offset": "+0",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
  }
}'
```

Response:
**CAUTION** If a redirect URL exists in the response object you MUST redirect the customer for payment completion

Create Payment response will contain `emerchantpay_payment` object. It will contain the current status of the payment.
Redirect URL will give you the next step.

States:
* error or declined - redirect URL will be the Failure URL filled in plugin settings
* approved - redirect URL will be the Success URL filled in the plugin settings
* pending_async - redirect URL will be the 3DSecure Method Continue endpoint for the next step of the payment

```json
{
  "data": {
    "id": "XXX",
    "type": "cart",
    "attributes": {...},
    "relationships": {...},
    "emerchantpay_payment": {
      "state": "pending_async",
      "redirect_url": "<customer-redirect-url>"
    }
  }
}
```

## Reference Actions
**CAUTION** the following transaction actions must be executed via Spree Admin backend:
* Capture
* Refund
* Void

## Contributing
Contribution directions go here.

## Development

### Running Specs

`rake test`

### Running Linters

`rake styles`

## License
The gem is available as open source under the terms of the [GPL-2.0 License](https://opensource.org/license/gpl-2-0/).

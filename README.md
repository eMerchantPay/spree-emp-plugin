emerchantpay Genesis Gateway for Spree
===========
[![Gem Version](https://badge.fury.io/rb/spree_emerchantpay_genesis.svg)](https://badge.fury.io/rb/spree_emerchantpay_genesis)
[![Software License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE)

Overview
--------
This is a Payment Module for Spree eCommerce that gives you the ability to process payments through emerchantpay's Payment Gateway - Genesis.

# Requirements
* Spree Core 4.x (Tested up to 4.10.1)
* Spree Backend 4.x (Tested up to 4.8.4)
* Spree FrontEnd - Optional (Tested up to 4.8.0)
* Ruby >= 2.7
* Ruby on Rails >= 6.1.4
* [GenesisRuby v0.2.2](https://github.com/GenesisGateway/genesis_ruby/releases/tag/0.2.2)
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
* For Provider choose `Spree::Gateway::EmerchantpayDirect` or `Spree:Gateway::EmerchantpayCheckout`
* Fill in Name, Description and Stores
* Click Create

# Usage

## Configuration
* Navigate to the `Spree::Gateway::EmerchantpayDirect` or `Spree:Gateway::EmerchantpayCheckout` payment method in the Configurations
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
<a id="payment-point-4"></a>
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

### Create Payment

#### Create Direct Payment  

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

**CAUTION** If a redirect URL exists in the response object you MUST redirect the customer for payment completion. Check [Response](#payment-response).  

#### Create Checkout Payment

The Checkout Gateway doesn't require `source_attributes` by default (see [p.4 Update Order](#payment-point-4)). Upon Order Update or Payment Create the only required parameter is `payment_method_id`.

In some cases, the Gateway Web Payment Form may require Custom Attributes. Those attributes can be passed to the gateway via `api/v2/storefront/checkout/create_payment`.
public_metadata contains a list with custom attributes where the key is the transaction type chosen on the payment method configuration inside the administration backend.

```bash
curl --request 'POST' \
  --header 'Accept: application/vnd.api+json' \
  --header 'X-Spree-Order-Token: EsDjq1oXEgKI6kuujgfvFw1694531383712' \
  --header 'Content-Type: application/vnd.api+json' \
  --url 'http://localhost:4000/api/v2/storefront/checkout/create_payment' \
  --data '{
  "payment_method_id": "8",
  "source_attributes": {
    "consumer_id":"123456",
    "consumer_email": "travis@example.com",
    "public_metadata": {
      "sale3d": { "bin": "401200", "tail": "0085"},
      "trustly_sale": {"return_success_url_target": "top"}
    }
  }
}'
```
Full list with the available Custom Attributes for every Transaction Type can be found [here](https://emerchantpay.github.io/gateway-api-docs/#wpf-transaction-types).

The payment can be finished and a request to the Gateway will be sent with one of the Order Next or Complete endpoints.  

* Order complete:
```bash
curl --request 'PATCH' \
  --header 'Accept: application/vnd.api+json' \
  --header 'X-Spree-Order-Token: EsDjq1oXEgKI6kuujgfvFw1694531383712' \
  --header 'Content-Type: application/vnd.api+json' \
  --url 'http://localhost:4000/api/v2/storefront/checkout/complete'
```
In the JSON Response document you will find a `redirect_url` where the customer must be redirected for completing the payment. Check [Response](#payment-response).

## Response:
<a id="payment-response"></a>
Create Payment response will contain `emerchantpay_payment` object. It will contain the current status of the payment.
Redirect URL will give you the next step.

States:
* error or declined - redirect URL will be the Failure URL filled in plugin settings
* approved - redirect URL will be the Success URL filled in the plugin settings
* pending_async - redirect URL will be the 3DSecure Method Continue endpoint for the next step of the payment
* new - redirect URL will be the Web Payment Form URL where the customer must finish the payment 

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

## Supported Transactions

* ```emerchantpay Direct``` Payment Method
  * __Authorize__
  * __Authorize (3D-Secure)__
  * __Sale__
  * __Sale (3D-Secure)__

* ```emerchantpay Checkout``` Payment Method
  * __Apple Pay__
  * __Argencard__
  * __Aura__
  * __Authorize__
  * __Authorize (3D-Secure)__
  * __Baloto__
  * __Bancomer__
  * __Bancontact__
  * __Banco de Occidente__
  * __Banco do Brasil__
  * __BitPay__
  * __Boleto__
  * __Bradesco__
  * __Cabal__
  * __CashU__
  * __Cencosud__
  * __Davivienda__
  * __Efecty__
  * __Elo__
  * __eps__
  * __eZeeWallet__
  * __Fashioncheque__
  * __Google Pay__
  * __iDeal__
  * __iDebit__
  * __InstaDebit__
  * __Intersolve__
  * __Itau__
  * __Klarna__
  * __Multibanco__
  * __MyBank__
  * __Naranja__
  * __Nativa__
  * __Neosurf__
  * __Neteller__
  * __Online Banking__
    * __Interac Combined Pay-in (CPI)__
    * __Bancontact (BCT)__
    * __BLIK (BLK)__
    * __SPEI (SE)__
    * __Post Finance (PF)__
    * __Santander (SN)__
    * __Itau (IT)__
    * __Bradesco (BR)__
    * __Banco do Brasil (BB)__
    * __Webpay (WP)__
    * __Bancomer (BN)__
    * __PSE (PS)__
    * __Banco de Occidente (BO)__
    * __PayID (PID)__
  * __OXXO__
  * __P24__
  * __Pago Facil__
  * __PayPal__
  * __PaySafeCard__
  * __PayU__
  * __Pix__
  * __POLi__
  * __Post Finance__
  * __PSE__
  * __RapiPago__
  * __Redpagos__
  * __SafetyPay__
  * __Sale__
  * __Sale (3D-Secure)__
  * __Santander__
  * __Sepa Direct Debit__
  * __SOFORT__
  * __Tarjeta Shopping__
  * __TCS__
  * __Trustly__
  * __TrustPay__
  * __UPI__
  * __WebMoney__
  * __WebPay__
  * __WeChat__

_Note_: If you have trouble with your credentials or terminal configuration, get in touch with our [support] team

## Development

### Running Specs

`rake test`

### Running Linters

`rake styles`

### Appraisals

#### Spree 4.4

`bundle exec appraisal spree-4.4 rake test`

#### Spree Master

`bundle exec appraisal spree-master rake test`

#### Configure

`bundle exec appraisal install`

### Build Demo store
Requires [Docker Engine](https://docs.docker.com/engine/install/)

1. Clone the project
2. Create .env file in the project rood based on the .env.example
   * Set `RAILS_ENV=production`
3. Execute inside project root:
   ```shell
   docker compose up
   ```
4. Setup Web Server with reverse proxy configuration

### Setup plugin for development
1. Clone the project
2. Create .env file based on the .env.example
   * Set `RAILS_ENV=development`
   * Set `PLUGIN_SOURCE=/<local path to the plugin source>`
3. Execute inside project root:
   ```shell
   docker compose -f compose.yaml -f development-compose.yaml up -d
   ```
   * Optional you can set project name with the -p flag
   * You can attach to the container and debug with `pry` (`docker attach <container>`). 
     Requires `config.web_console.whitelisted_ips = '<host_ip>'` inside the container (/mnt/spree/config/environments/development.rb)
   * If you expose the localhost (ex. ngrok) requires `config.hosts.clear` inside the container (/mnt/spree/config/environments/development.rb)

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/license/mit).

[support]: mailto:tech-support@emerchantpay.net

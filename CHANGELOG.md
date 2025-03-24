0.1.12
-----
**Features**:

* Updated Genesis Ruby to version 0.2.2
* Renamed Latipay bank code to PayID

0.1.11
-----
**Features**:

* Added Smart Router support through the Direct payment method
* Update Genesis Ruby to version 0.2.0
* Tested up to Spree Core 4.10.1

0.1.10
-----
**Features**:

* Improved plugin compatibility with the others
* Updated project dependencies
* Updated Threeds CSS used by the Spree Frontend

0.1.9
-----
**Features**:

* Added the following Bank Codes support for Online Banking transaction type through the Checkout payment method:
  * Interac Combined Pay-in (CPI)
  * Bancontact (BCT)
  * BLIK (BLK)
  * SPEI (SE)
  * Post Finance (PF)
  * Santander (SN)
  * Itau (IT)
  * Bradesco (BR)
  * Banco do Brasil (BB)
  * Webpay (WP)
  * Bancomer (BN)
  * PSE (PS)
  * Banco de Occidente (BO)
  * LatiPay (PID)

0.1.8
-----
**Features**:

* Updated Genesis Ruby SDK to version 0.1.7
* Updated Card JS to the latest
* Updated transaction type list in the emerchantpay Checkout payment method
* Removed GiroPay transaction type
* Added Spree eCommerce version 4.8.x support

0.1.7
-----
**Features**:

* Added the following Mobile transaction types support through the emerchantpay Checkout payment method:
  * Apple Pay
  * Google Pay
  * Pay Pal

0.1.6
-----
**Features**:

* Added Docker project
* Added Spree Rails FrontEnd Redirect URL handling (asynchronous payments)
* Updated README

0.1.5
-----
**Features**:

* Added `emerchantpay Checkout` Description field handling
* Updated Genesis Ruby SDK to version 0.1.6
* Updated project dependencies
* Added `emerchantpay Checkout` Custom Attributes handling
* Added `emerchantpay Checkout` Language support

0.1.4
-----
**Features**:

* Added `EmerchantpayCheckout` payment method
* Updated Genesis Ruby SDK to version 0.1.5
* Update Card JS to the latest version

**Fixes**:

* Fixed project's URLs listed on RubyGems

0.1.3
-----
**Features**

* Added tests to the library
* Added Appraisals for Spree 4.4 and Spree main GitHub Branch
* Added `spree_emerchantpay_genesis` to [RubyGems](https://rubygems.org/gems/spree_emerchantpay_genesis)

**Fixes**:

* Fixed 3DSv2 parameters handling
* Fixed engine installation without Spree Rails Frontend
* Fixed minor issues

0.1.2
-----

**Features**:

* Updated project license to MIT
* Added support for the following transaction types:
  * Authorize 3D
  * Sale 3D
* Added 3DSv2 parameters support to the 3D payments
* Added support for 3DSv2 payment flow
* Added `emerchantpay_payment` inside Spree API V2 Create Payment response containing payment state and redirect_url
* Added Gateway Notifications handling used for asynchronous payments
* Updated Genesis Ruby SDK to version 0.1.3

0.1.1
-----

**Features**:

* Added support for the following reference payment actions via Genesis Gateway:
  * Capture
  * Void
  * Refund

0.1.0
-----

**Features**:

* Added initial code base for emerchantpay Gateway Module for Spree payment method
* Added EmerchantpayDirect Spree Gateway
* Added Spree Payment Creation decoration
* Added Spree Payment Methods settings decorator
* Added Payment Source View decorator
* Added Spree V2 Checkout controller decorator
* Added Emerchantpay Payments database migration
* Added Spree Payment Processing decorator

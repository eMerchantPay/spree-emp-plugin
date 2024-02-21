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

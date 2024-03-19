module Spree
  module PermittedAttributes

    # month / year may be provided by some sources, or others may elect to use one field
    @@source_attributes = [ # rubocop:disable Style/ClassVars
      :number, :month, :year, :expiry, :verification_value,
      :first_name, :last_name, :cc_type, :gateway_customer_profile_id,
      :gateway_payment_profile_id, :last_digits, :name, :encrypted_data,
      :consumer_id, :consumer_email
    ]

  end
end

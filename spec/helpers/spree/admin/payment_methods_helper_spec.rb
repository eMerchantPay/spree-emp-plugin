require 'stubs/payment_method_helper_stub'

RSpec.describe Spree::Admin::PaymentMethodsHelper do
  include ActionView::TestCase::Behavior

  let(:helper) { SpreeEmerchantpayGenesisSpec::Stubs::PaymentMethodHelperStub.new }
  let(:payment_method) { create(:emerchantpay_direct_gateway) }
  let(:options) { { type: :string, values: nil, selected: 'selected' } }
  let(:form) do
    ActionView::Helpers::FormBuilder.new(
      'gateway_emerchantpay_direct',
      payment_method,
      view,
      {
        url:  "/admin/payment_methods/#{payment_method.id}",
        html: {
          class:              'edit_gateway_emerchantpay_direct',
          id:                 "edit_gateway_emerchantpay_direct_#{payment_method.id}",
          method:             :patch,
          authenticity_token: nil
        }
      }
    )
  end

  it 'when common preference fields' do
    expect(helper.preference_fields(payment_method, form)).to_not be_empty
  end

  it 'when boolean preference fields' do
    allow(payment_method).to receive_messages preference_type: :boolean

    expect(helper.preference_fields(payment_method, form)).to_not be_empty
  end

  describe 'when preference_field_for' do
    it 'with input text field type' do
      expect(helper.preference_field_for(form, 'preferred_username', options)).to include 'type="text"'
    end

    it 'with boolean field type' do
      options[:type] = :boolean

      expect(helper.preference_field_for(form, 'preferred_test_mode', options)).to include 'type="checkbox"'
    end

    it 'with password type' do
      options[:type] = :password

      expect(helper.preference_field_for(form, 'preferred_password', options)).to include 'type="password"'
    end

    it 'with textarea type' do
      options[:type] = :text

      expect(helper.preference_field_for(form, 'preferred_token', options)).to include '</textarea>'
    end

    it 'with boolean select type' do
      options[:type] = :boolean_select
      options[:selected] = 'true'
      options[:value] = %w(true false)

      expect(helper.preference_field_for(form, 'preferred_threeds_allowed', options))
        .to include '<option selected="selected" value="true">Enabled</option>'
    end

    it 'with select type' do
      options[:type]     = :select
      options[:selected] = 'authorize'
      options[:values]   = [:authorize, :authorize3d, :sale, :sale3d]

      expect(helper.preference_field_for(form, 'preferred_transaction_types', options))
        .to include '<option selected="selected" value="authorize">Authorize</option>'
    end

    it 'with default type' do
      options[:type] = :some_type

      expect(helper.preference_field_for(form, 'preferred_username', options)).to include 'type="text"'
    end
  end

  describe 'when preference_field_tag' do
    it 'with input text field type' do
      expect(helper.preference_field_tag('preferred_username', 'preferred_username', options)).to include 'type="text"'
    end

    it 'with boolean field type' do
      options[:type] = :boolean

      expect(helper.preference_field_tag('preferred_test_mode', 'preferred_test_mode', options))
        .to include 'type="checkbox"'
    end

    it 'with password type' do
      options[:type] = :password

      expect(helper.preference_field_tag('preferred_password', 'preferred_password', options))
        .to include 'type="password"'
    end

    it 'with textarea type' do
      options[:type] = :text

      expect(helper.preference_field_tag('preferred_token', 'preferred_token', options)).to include '</textarea>'
    end

    it 'with boolean select type' do
      options[:type] = :boolean_select
      options[:selected] = 'true'
      options[:value] = %w(true false)

      expect(helper.preference_field_tag('preferred_threeds_allowed', 'preferred_threeds_allowed', options))
        .to include '>preferred_threeds_allowed</select>'
    end

    it 'with select type' do
      options[:type]     = :select
      options[:selected] = 'authorize'
      options[:values]   = [:authorize, :authorize3d, :sale, :sale3d]

      expect(helper.preference_field_tag('preferred_transaction_types', 'preferred_transaction_types', options))
        .to include '>preferred_transaction_types</select>'
    end

    it 'with default type' do
      options[:type] = :some_type

      expect(helper.preference_field_tag('preferred_username', 'preferred_username', options)).to include 'type="text"'
    end
  end
end

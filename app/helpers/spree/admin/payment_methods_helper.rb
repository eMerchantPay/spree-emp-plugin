module Spree
  module Admin
    # Spree Payment Methods Helper for adding HTML elements (ex. select) for the Payment Method
    module PaymentMethodsHelper

      def preference_field_for(form, field, options) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        case options[:type]
        when :integer, :string
          form.text_field(field, preference_field_options(options))
        when :boolean
          form.check_box(field, preference_field_options(options))
        when :password
          form.password_field(field, preference_field_options(options))
        when :text
          form.text_area(field, preference_field_options(options))
        when :boolean_select
          label_tag(field, Spree.t(field))
          form.select(field, { Spree.t(:enabled) => true, Spree.t(:disabled) => false }, {}, class: 'select2')
        when :select
          label_tag(field, Spree.t(field))
          form.select(
            field,
            options_for_select(
              options[:values].map { |key| [I18n.t(key, scope: 'emerchantpay.preferences'), key] }, options[:selected]
            ),
            {},
            class: 'select2'
          )
        else
          form.text_field(field, preference_field_options(options))
        end
      end

      def preference_field_tag(name, value, options) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        case options[:type]
        when :integer, :string
          text_field_tag(name, value, preference_field_options(options))
        when :boolean
          hidden_field_tag(name, 0, id: "#{name}_hidden") +
            check_box_tag(name, 1, value, preference_field_options(options))
        when :password
          password_field_tag(name, value, preference_field_options(options))
        when :text
          text_area_tag(name, value, preference_field_options(options))
        when :boolean_select
          select_tag(name, value, preference_field_options(options))
        when :select
          select_tag(name, value, preference_field_options(options))
        else
          text_field_tag(name, value, preference_field_options(options))
        end
      end

      def preference_fields(object, form)
        return unless object.respond_to?(:preferences)

        get_preference_fields(object, object.preferences.keys, form)
      end

      def get_preference_fields(object, keys, form)
        keys.reject { |k| k == :currency_merchant_accounts }.map do |key|
          next if !object.has_preference?(key) || default_preference_support?(object, key)

          if object.preference_type(key) == :boolean
            add_boolean_preference(object, key, form)
          else
            add_common_preference(object, key, form)
          end
        end.join(' ').html_safe
      end

      private

      def add_boolean_preference(object, key, form)
        content_tag(
          :div,
          preference_field_for(
            form,
            "preferred_#{key}", type: object.preference_type(key)
          ) + form.label("preferred_#{key}", Spree.t(key), class: 'form-check-label'),
          class: 'form-group form-check',
          id: [object.class.to_s.parameterize, 'preference', key].join('-')
        )
      end

      def add_common_preference(object, key, form)
        content_tag(:div, class: 'form-group', 'data-hook' => "preferred_#{key}") do
          form.label("preferred_#{key}", "#{Spree.t(key)}: ") + preference_field_for(
            form,
            "preferred_#{key}",
            type:     object.preference_type(key),
            values:   (object.__send__("preferred_#{key}_default").is_a?(Hash) ? object.__send__("preferred_#{key}_default")[:values] : nil), # rubocop:disable Layout/LineLength
            selected: object.preferences[key]
          )
        end
      end

      def default_preference_support?(object, preference)
        unsupported_default_preferences.include?(preference.to_s) &&
          object.instance_of?(Spree::Gateway::EmerchantpayDirect)
      end

      # Not Supported preferences from Emerchantpay Gateway
      def unsupported_default_preferences
        %w(server)
      end

    end
  end
end

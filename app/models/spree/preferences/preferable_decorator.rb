module Spree
  module Preferences
    # Spree Payment Method Decorator
    # Extends payment methods configurable field types
    module PreferableDecorator

      private

      def convert_preference_value(value, type) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        case type
        when :string, :text, :select
          value.to_s
        when :password
          value.to_s
        when :decimal
          value.to_d
        when :integer
          value.to_i
        when :boolean, :boolean_select
          if value.is_a?(FalseClass) ||
             value.nil? ||
             value == 0 || # rubocop:disable Style/NumericPredicate
             value =~ /^(f|false|0)$/i ||
             (value.respond_to?(:empty?) && value.empty?)
            false
          else
            true
          end
        when :array
          value.is_a?(Array) ? value : Array.wrap(value)
        when :hash
          case value.class.to_s
          when 'Hash'
            value
          when 'String'
            # only works with hashes whose keys are strings
            JSON.parse value.gsub('=>', ':')
          when 'Array'
            begin
              value.try(:to_h)
            rescue TypeError
              Hash[*value]
            rescue ArgumentError
              raise 'An even count is required when passing an array to be converted to a hash'
            end
          else
            value.class.ancestors.include?(Hash) ? value : {}
          end
        else
          value
        end
      end

    end
  end
end

::Spree::Preferences::Preferable.prepend(Spree::Preferences::PreferableDecorator)

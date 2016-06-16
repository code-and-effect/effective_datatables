module Effective
  module EffectiveDatatable
    module Helpers

      # When we order by Array, it's already a string.
      # This gives us a mechanism to sort numbers as numbers
      def convert_to_column_type(table_column, value)
        return value if table_column[:sortable] == :raw

        if value.html_safe? && value.kind_of?(String) && value.start_with?('<')
          value = ActionView::Base.full_sanitizer.sanitize(value)
        end

        case table_column[:type]
        when :number, :price, :decimal, :float, :percentage
          (value.to_s.gsub(/[^0-9|\.]/, '').to_f rescue 0.00)
        when :integer
          (value.to_s.gsub(/\D/, '').to_i rescue 0)
        else
          value
        end
      end

    end
  end
end

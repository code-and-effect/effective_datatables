module Effective
  module EffectiveDatatable
    module Filters

      protected

      # The datatable has just passed the string value of any filters
      # We need to convert it into the correct datatype
      def parse_filter(filter, value)
        return filter[:parse].call(value) if filter[:parse]

        case filter[:value] # This is the default value as per filter DSL method
        when ActiveSupport::TimeWithZone
          if filter[:name].to_s.start_with?('end_')
            Time.zone.parse(value).end_of_day
          else
            Time.zone.parse(value)
          end
        when TrueClass, FalseClass
          [true, 'true', '1'].include?(value)
        when Fixnum
          value.to_i
        when Float
          value.to_f
        when String
          value.to_s
        when NilClass
          value.presence
        else
          raise 'unsupported type'
        end
      end

    end
  end
end

module Effective
  module EffectiveDatatable
    module Filters

      # The datatable has just passed the string value of any filters
      # We need to convert it into the correct datatype
      def parse_filter(filter, filter_term)
        return filter[:parse].call(filter_term) if filter[:parse]

        case filter[:value] # This is the default value as per filter DSL method
        when ActiveSupport::TimeWithZone
          if filter[:name].to_s.start_with?('end_')
            Time.zone.parse(filter_term).end_of_day
          else
            Time.zone.parse(filter_term)
          end
        when TrueClass, FalseClass
          [true, 'true', '1'].include?(filter_term)
        when Fixnum
          filter_term.to_i
        when Float
          filter_term.to_f
        when String
          filter_term.to_s
        when NilClass
          filter_term.presence
        else
          raise 'unsupported type'
        end
      end

    end
  end
end

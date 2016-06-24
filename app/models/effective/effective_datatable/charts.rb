module Effective
  module EffectiveDatatable
    module Charts

      def charts_data
        HashWithIndifferentAccess.new().tap do |retval|
          (charts || {}).each do |name, chart|
            retval[name] = {
              name: chart[:name],
              type: chart[:type],
              options: chart[:options],
              data: (instance_exec(&chart[:block]) if chart[:block])
            }
          end
        end
      end

    end
  end
end

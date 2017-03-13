module Effective
  module EffectiveDatatable
    module Dsl
      module View

        # Same as calling filter
        def filters
          datatable.state[:filter]
        end

        def search
          datatable.state[:search]
        end

      end
    end
  end
end

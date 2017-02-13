module Effective
  module EffectiveDatatable
    module Dsl
      module View

        def attributes
          datatable.attributes
        end

        # Same as calling scope
        def current_scope
          datatable.state[:scope]
        end

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

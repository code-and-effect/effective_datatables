module Effective
  module EffectiveDatatable
    module Dsl
      module View
        def attributes
          datatable.attributes
        end

        def current_scope
          datatable.state[:scope]
        end

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

# These are Class level methods.

module Effective
  module EffectiveDatatable
    module Dsl

      def datatable(&block)
        define_method('initialize_datatable') { instance_exec(&block) }
      end

      def scopes(&block)
        define_method('initialize_scopes') { instance_exec(&block) }
      end

      def charts(&block)
        define_method('initialize_charts') { instance_exec(&block) }
      end

    end
  end
end

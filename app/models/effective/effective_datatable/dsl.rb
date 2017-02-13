# These are Class level methods.

module Effective
  module EffectiveDatatable
    module Dsl

      def bulk_actions(&block)
        define_method('initialize_bulk_actions') { view.instance_exec(&block) }
      end

      def charts(&block)
        define_method('initialize_charts') { view.instance_exec(&block) }
      end

      def collection(&block)
        define_method('initialize_collection') { view.datatable.collection = view.instance_exec(&block) }
      end

      def datatable(&block)
        define_method('initialize_datatable') { view.instance_exec(&block) }
      end

      def filters(&block)
        define_method('initialize_filters') { view.instance_exec(&block) }
      end

    end
  end
end

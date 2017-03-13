# These are Class level methods.

module Effective
  module EffectiveDatatable
    module Dsl

      def bulk_actions(&block)
        define_method('initialize_bulk_actions') { dsl_tool.instance_exec(&block) }
      end

      def charts(&block)
        define_method('initialize_charts') { dsl_tool.instance_exec(&block) }
      end

      # def collection(&block)
      #   define_method('initialize_collection') { dsl_tool.datatable.collection = dsl_tool.instance_exec(&block) }
      # end

      def datatable(&block)
        define_method('initialize_datatable') { dsl_tool.instance_exec(&block) }
      end

      def filters(&block)
        define_method('initialize_filters') { dsl_tool.instance_exec(&block) }
      end

      def helpers(&block)
        define_method('initialize_helpers') { dsl_tool.instance_exec(&block) }
      end

    end
  end
end

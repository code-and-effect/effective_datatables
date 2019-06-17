module Effective
  module EffectiveDatatable
    module Dsl

      def bulk_actions(&block)
        define_method('initialize_bulk_actions') { dsl_tool.instance_exec(&block); dsl_tool.bulk_actions_col }
      end

      def charts(&block)
        define_method('initialize_charts') { dsl_tool.instance_exec(&block) }
      end

      def collection(apply_belongs_to: true, apply_scope: true, &block)
        define_method('initialize_collection') { 
          self._collection_apply_belongs_to = apply_belongs_to
          self._collection_apply_scope = apply_scope
          
          self._collection = dsl_tool.instance_exec(&block) 
        }
      end

      def datatable(&block)
        define_method('initialize_datatable') do
          dsl_tool.in_datatables_do_block = true
          dsl_tool.instance_exec(&block)
          dsl_tool.in_datatables_do_block = false
        end
      end

      def filters(&block)
        define_method('initialize_filters') { dsl_tool.instance_exec(&block) }
      end

    end
  end
end

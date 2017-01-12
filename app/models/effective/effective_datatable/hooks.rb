module Effective
  module EffectiveDatatable
    module Hooks

      # Called on the final collection after searching, ordering, arrayizing and formatting have been completed
      def finalize(collection) # Override me if you like
        collection
      end

      # Override this function to perform custom searching on a column
      def search_column(collection, table_column, search_term, sql_column_or_index)
        if table_column[:array_column]
          array_tool.search_column_with_defaults(collection, table_column, search_term, sql_column_or_index)
        else
          table_tool.search_column_with_defaults(collection, table_column, search_term, sql_column_or_index)
        end
      end

      # Override this function to perform custom ordering on a column
      # direction will be :asc or :desc
      def order_column(collection, table_column, direction, sql_column_or_index)
        if table_column[:array_column]
          array_tool.order_column_with_defaults(collection, table_column, direction, sql_column_or_index)
        else
          table_tool.order_column_with_defaults(collection, table_column, direction, sql_column_or_index)
        end
      end
    end
  end
end

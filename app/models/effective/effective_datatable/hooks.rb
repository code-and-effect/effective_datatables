module Effective
  module EffectiveDatatable
    module Hooks

      # Called on the final collection after searching, ordering, arrayizing and formatting have been completed
      def finalize(collection) # Override me if you like
        collection
      end

      # Override this function to perform custom searching on a column
      def search_column(collection, column, search_term, sql_column_or_index)
        if column[:sql_column]
          table_tool.search_column(collection, column, search_term, sql_column_or_index)
        else
          array_tool.search_column(collection, column, search_term, sql_column_or_index)
        end
      end

      # Override this function to perform custom ordering on a column
      # direction will be :asc or :desc
      def order_column(collection, column, direction, sql_column_or_index)
        if column[:sql_column]
          table_tool.order_column(collection, column, direction, sql_column_or_index)
        else
          array_tool.order_column(collection, column, direction, sql_column_or_index)
        end
      end

      # The incoming value could be from the passed page params or from the AJAX request.
      # When we parse an incoming filter term for this filter.
      def parse_filter_value(filter, value)
        return filter[:parse].call(value) if filter[:parse]
        Effective::Attribute.new(filter[:value]).parse(value, name: filter[:name])
      end

    end
  end
end

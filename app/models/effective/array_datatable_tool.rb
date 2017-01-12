module Effective
  # The collection is an Array of Arrays
  class ArrayDatatableTool
    attr_accessor :table_columns

    delegate :page, :per_page, :search_column, :order_column, :display_table_columns, :convert_to_column_type, :to => :@datatable

    def initialize(datatable, table_columns)
      @datatable = datatable
      @table_columns = table_columns
    end

    def search_terms
      @search_terms ||= @datatable.search_terms.select { |name, search_term| table_columns.key?(name) }
    end

    def order_by_column
      @order_by_column ||= table_columns[@datatable.order_name]
    end

    def order(collection)
      return collection unless order_by_column.present?

      column_order = order_column(collection, order_by_column, @datatable.order_direction, display_index(order_by_column))
      raise 'order_column must return an Array' unless column_order.kind_of?(Array)
      column_order
    end

    def order_column_with_defaults(collection, table_column, direction, index)
      if direction == :asc
        collection.sort! do |x, y|
          if (x[index] && y[index])
            x[index] <=> y[index]
          elsif x[index]
            -1
          elsif y[index]
            1
          else
            0
          end
        end
      else
        collection.sort! do |x, y|
          if (x[index] && y[index])
            y[index] <=> x[index]
          elsif x[index]
            1
          elsif y[index]
            -1
          else
            0
          end
        end
      end

      collection
    end

    def search(collection)
      search_terms.each do |name, search_term|
        column_search = search_column(collection, table_columns[name], search_term, display_index(table_columns[name]))
        raise 'search_column must return an Array object' unless column_search.kind_of?(Array)
        collection = column_search
      end
      collection
    end

    def search_column_with_defaults(collection, table_column, search_term, index)
      search_term = search_term.downcase if table_column[:filter][:fuzzy]

      collection.select! do |row|
        if table_column[:filter][:fuzzy]
          row[index].to_s.downcase.include?(search_term)
        else
          row[index] == search_term
        end
      end || collection
    end

    def paginate(collection)
      Kaminari.paginate_array(collection).page(page).per(per_page)
    end

    private

    def display_index(column)
      display_table_columns.present? ? display_table_columns.keys.index(column[:name]) : column[:index]
    end

  end
end

# [
#   [1, 'title 1'],
#   [2, 'title 2'],
#   [3, 'title 3']
# ]

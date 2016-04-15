module Effective
  # The collection is an Array of Arrays
  class ArrayDatatableTool
    attr_accessor :table_columns

    delegate :order_name, :order_direction, :page, :per_page, :search_column, :display_table_columns, :to => :@datatable

    def initialize(datatable, table_columns)
      @datatable = datatable
      @table_columns = table_columns
    end

    def search_terms
      @search_terms ||= @datatable.search_terms.select { |name, search_term| table_columns.key?(name) }
    end

    def order_column
      @order_column ||= table_columns[order_name]
    end

    def order(collection)
      if order_column.present?
        index = display_index(order_column)

        if order_direction == 'ASC'
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
      end

      collection
    end

    def search(collection)
      search_terms.each do |name, search_term|
        column_search = search_column(collection, table_columns[name], search_term)
        raise 'search_column must return an Array object' unless column_search.kind_of?(Array)
        collection = column_search
      end
      collection
    end

    def search_column_with_defaults(collection, table_column, search_term)
      search_term = search_term.downcase
      index = display_index(table_column)

      collection.select! do |row|
        value = row[index].to_s.downcase

        if table_column[:filter][:type] == :select && table_column[:filter][:fuzzy] != true
          value == search_term
        else
          value.include?(search_term)
        end
      end || collection
    end

    def paginate(collection)
      Kaminari.paginate_array(collection).page(page).per(per_page)
    end

    private

    def display_index(column)
      display_table_columns.present? ? display_table_columns.keys.index(column[:name]) : column[:array_index]
    end

  end
end

# [
#   [1, 'title 1'],
#   [2, 'title 2'],
#   [3, 'title 3']
# ]

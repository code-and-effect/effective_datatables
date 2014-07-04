module Effective
  # The collection is an Array of Arrays
  class ArrayDatatableTool
    attr_accessor :table_columns

    delegate :order_column_index, :order_direction, :page, :per_page, :search_column, :to => :@datatable

    def initialize(datatable, table_columns)
      @datatable = datatable
      @table_columns = table_columns
    end

    def order_column
      @order_column ||= table_columns.find { |_, values| values[:index] == order_column_index }.try(:second) # This pulls out the values
    end

    def search_terms
      @search_terms ||= @datatable.search_terms.select { |name, search_term| table_columns.key?(name) }
    end

    def order(collection)
      if order_column.present?
        if order_direction == 'ASC'
          collection.sort! { |x, y| x[order_column[:index]] <=> y[order_column[:index]] }
        else
          collection.sort! { |x, y| y[order_column[:index]] <=> x[order_column[:index]] }
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

      collection.select! do |row|
        value = row[table_column[:index]].downcase

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
  end
end

# [
#   [1, 'title 1'],
#   [2, 'title 2'],
#   [3, 'title 3']
# ]

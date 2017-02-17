module Effective
  # The collection is an Array of Arrays
  class ArrayDatatableTool
    attr_reader :datatable
    attr_reader :columns

    def initialize(datatable)
      @datatable = datatable
      @columns = datatable.columns.select { |_, col| col[:array_column] }
    end

    def size(collection)
      collection.size
    end

    def searched
      @searched ||= datatable.search_terms.select { |name, _| columns.key?(name) }
    end

    def ordered
      @ordered ||= columns[datatable.order_name]
    end

    def order(collection)
      return collection unless ordered.present?

      collection = datatable.order_column(collection, ordered, datatable.order_direction, display_index(ordered))
      raise 'order_column must return an Array' unless collection.kind_of?(Array)
      collection
    end

    def order_column(collection, column, direction, index)
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
      searched.each do |name, search_term|
        collection = datatable.search_column(collection, columns[name], search_term, display_index(columns[name]))
        raise 'search_column must return an Array object' unless collection.kind_of?(Array)
      end
      collection
    end

    def search_column(collection, column, search_term, index)
      search_term = search_term.downcase if column[:search][:fuzzy]

      collection.select! do |row|
        if column[:search][:fuzzy]
          row[index].to_s.downcase.include?(search_term)
        else
          row[index] == search_term
        end
      end || collection
    end

    def paginate(collection)
      Kaminari.paginate_array(collection).page(datatable.page).per(datatable.per_page)
    end

    private

    def display_index(column)
      display_columns.present? ? display_columns.keys.index(column[:name]) : column[:index]
    end

  end
end

# [
#   [1, 'title 1'],
#   [2, 'title 2'],
#   [3, 'title 3']
# ]

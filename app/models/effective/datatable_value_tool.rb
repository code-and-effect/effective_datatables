module Effective
  # The collection is an Array of Arrays
  class DatatableValueTool
    attr_reader :datatable
    attr_reader :columns

    def initialize(datatable)
      @datatable = datatable

      if datatable.array_collection?
        @columns = datatable.columns
      else
        @columns = datatable.columns.select { |_, col| col[:sql_column].blank? }
      end
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

      collection = datatable.order_column(collection, ordered, datatable.order_direction, ordered[:index])
      raise 'order_column must return an Array' unless collection.kind_of?(Array)
      collection
    end

    def order_column(collection, column, direction, index)
      Rails.logger.info "VALUE TOOL: order_column #{column} #{direction} #{index}"

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
      searched.each do |name, value|
        collection = datatable.search_column(collection, columns[name], value, columns[name][:index])
        raise 'search_column must return an Array object' unless collection.kind_of?(Array)
      end
      collection
    end

    def search_column(collection, column, value, index)
      Rails.logger.info "VALUE TOOL: search_column #{column} #{value} #{index}"

      value = value.downcase if column[:search][:fuzzy]

      collection.select! do |row|
        if column[:search][:fuzzy]
          row[index].to_s.downcase.include?(value)
        else
          row[index] ==value
        end
      end || collection
    end

    def paginate(collection)
      Kaminari.paginate_array(collection).page(datatable.page).per(datatable.per_page)
    end

  end
end

# [
#   [1, 'title 1'],
#   [2, 'title 2'],
#   [3, 'title 3']
# ]

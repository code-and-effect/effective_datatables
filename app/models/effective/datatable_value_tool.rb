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
      @searched ||= datatable.search.select { |name, _| columns.key?(name) }
    end

    def ordered
      @ordered ||= columns[datatable.order_name]
    end

    def order(collection)
      return collection unless ordered.present?

      if ordered[:sort_method]
        collection = datatable.dsl_tool.instance_exec(collection, datatable.order_direction, ordered, ordered[:index], &ordered[:sort_method])
      else
        collection = order_column(collection, datatable.order_direction, ordered, ordered[:index])
      end

      raise 'sort method must return an Array' unless collection.kind_of?(Array)

      collection
    end

    def order_column(collection, direction, column, index)
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
            -1
          elsif y[index]
            1
          else
            0
          end
        end
      end

      collection
    end

    def search(collection)
      searched.each do |name, value|
        column = columns[name]

        if column[:search_method]
          collection = datatable.dsl_tool.instance_exec(collection, value, column, column[:index], &column[:search_method])
        else
          collection = search_column(collection, value, column, column[:index])
        end

        raise 'search_ must return an Array object' unless collection.kind_of?(Array)
      end

      collection
    end

    def search_column(collection, value, column, index)
      Rails.logger.info "VALUE TOOL: search_column #{column} #{value} #{index}"

      term = Effective::Attribute.new(column[:as]).parse(value, name: column[:name])

      collection.select! do |row|
        if column[:search][:fuzzy]
          case column[:as]
          when :duration
            if term < 0
              row[index] < term && row[index] > (term - 60)
            else
              row[index] >= term && row[index] < (term + 60)
            end
          when :string, :text
            row[index].to_s.downcase.include?(term.downcase)
          else
            row[index] == term
          end
        else # Not fuzzy
          row[index] == term
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

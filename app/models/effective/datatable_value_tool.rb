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
      Rails.logger.info "VALUE TOOL: order_column :#{column.to_s} :#{direction} #{index}"

      if direction == :asc
        collection.sort! do |x, y|
          x[index] <=> y[index] || x[index].to_s <=> y[index].to_s || 0
        end
      else
        collection.sort! do |x, y|
          y[index] <=> x[index] || y[index].to_s <=> x[index].to_s || 0
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

        raise 'search method must return an Array object' unless collection.kind_of?(Array)
      end

      collection
    end

    def search_column(collection, value, column, index)
      Rails.logger.info "VALUE TOOL: search_column #{column} #{value} #{index}"

      fuzzy = column[:search][:fuzzy]
      term = Effective::Attribute.new(column[:as]).parse(value, name: column[:name])
      term_downcased = term.downcase if fuzzy && term.kind_of?(String)

      # See effective_resources gem search() method # relation.rb
      collection.select! do |row|
        case column[:as]
        when :duration
          if fuzzy && (term % 60 == 0) && value.to_s.include?('m') == false
            if term < 0
              row[index] <= term && row[index] > (term - 60)
            else
              row[index] >= term && row[index] < (term + 60)
            end
          else
            row[index] == term
          end
        when :decimal, :currency
          if fuzzy && (term.round(0) == term) && value.to_s.include?('.') == false
            if term < 0
              row[index] <= term && row[index] > (term - 1.0)
            else
              row[index] >= term && row[index] < (term + 1.0)
            end
          else
            row[index] == term
          end
        when :resource
          Array(row[index]).any? do |resource|
            if term.kind_of?(Integer) && resource.respond_to?(:id)
              resource.id == term || resource.to_param == term
            elsif term.kind_of?(Array) && resource.respond_to?(:id)
              term.any? { |term| resource.id == term || resource.to_param == term || resource.to_param == value }
            else
              fuzzy ? resource.to_s.downcase == term_downcased : resource.to_s == term
            end
          end
        when :string, :text, :email
          if fuzzy
            row[index].to_s.downcase.include?(term_downcased)
          else
            row[index] == term
          end
        else
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

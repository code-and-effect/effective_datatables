module Effective
  class ActiveRecordDatatableTool
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
        collection.order("#{order_column[:column]} #{order_direction} NULLS #{order_direction == 'ASC' ? 'LAST' : 'FIRST'}")
      else
        collection
      end
    end

    def search(collection)
      search_terms.each do |name, search_term|
        column_search = search_column(collection, table_columns[name], search_term)
        raise 'search_column must return an ActiveRecord::Relation object' unless column_search.kind_of?(ActiveRecord::Relation)
        collection = column_search
      end
      collection
    end

    def search_column_with_defaults(collection, table_column, search_term)
      column = table_column[:column]

      collection.where(
        case table_column[:type]
        when :string, :text
          if table_column[:filter][:type] == :select && table_column[:filter][:fuzzy] != true
            "#{column} = :search_term"
          else
            search_term = "%#{search_term}%"
            "#{column} ILIKE :search_term"
          end
        when :datetime
          search_term = "%#{search_term}%"
          "to_char(#{column} AT TIME ZONE 'GMT', 'YYYY-MM-DD HH24:MI:SS') ILIKE :search_term"
        when :integer
          search_term = search_term.to_i
          "#{column} = :search_term"
        when :year
          "EXTRACT(YEAR FROM #{column}) = :search_term"
        when :boolean
          "#{column} = :search_term"
        else
          "#{column} = :search_term"
        end,
        {:search_term => search_term}
      )
    end

    def paginate(collection)
      collection.page(page).per(per_page)
    end

  end
end

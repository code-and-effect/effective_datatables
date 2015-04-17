module Effective
  class ActiveRecordDatatableTool
    attr_accessor :table_columns

    delegate :order_name, :order_direction, :page, :per_page, :search_column, :to => :@datatable

    def initialize(datatable, table_columns)
      @datatable = datatable
      @table_columns = table_columns
    end

    def search_terms
      @search_terms ||= @datatable.search_terms.select { |name, search_term| table_columns.key?(name) }
    end

    def order_column
      @order_column ||= table_columns.find { |_, values| values[:name] == order_name }.try(:second) # This pulls out the values
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

    def search_column_with_defaults(collection, table_column, term)
      column = table_column[:column]

      case table_column[:type]
      when :string, :text
        if table_column[:filter][:type] == :select && table_column[:filter][:fuzzy] != true
          collection.where("#{column} = :term", :term => term)
        else
          collection.where("#{column} ILIKE :term", :term => "%#{term}%")
        end
      when :datetime
        begin
          digits = term.scan(/(\d+)/).flatten.map(&:to_i)
          start_at = Time.zone.local(*digits)

          case digits.length
          when 1  # Year
            end_at = start_at.end_of_year
          when 2 # Year-Month
            end_at = start_at.end_of_month
          when 3 # Year-Month-Day
            end_at = start_at.end_of_day
          when 4 # Year-Month-Day Hour
            end_at = start_at.end_of_hour
          when 5 # Year-Month-Day Hour-Minute
            end_at = start_at.end_of_minute
          when 6
            end_at = start_at + 1.second
          else
            end_at = start_at
          end

          collection.where("#{column} >= :start_at AND #{column} <= :end_at", :start_at => start_at, :end_at => end_at)
        rescue => e
          collection
        end
      when :obfuscated_id
        if (deobfuscated_id = collection.deobfuscate(term)) == term # We weren't able to deobfuscate it, so this is an Invalid ID
          collection.where("#{column} = :term", :term => 0)
        else
          collection.where("#{column} = :term", :term => deobfuscated_id)
        end
      when :integer
        collection.where("#{column} = :term", :term => term.to_i)
      when :year
        collection.where("EXTRACT(YEAR FROM #{column}) = :term", :term => term.to_i)
      else
        collection.where("#{column} = :term", :term => term)
      end
    end

    def paginate(collection)
      collection.page(page).per(per_page)
    end

  end
end

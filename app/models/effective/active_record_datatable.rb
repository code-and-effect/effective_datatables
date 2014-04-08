module Effective
  module ActiveRecordDatatable
    def order(collection)
      col = table_columns[table_columns.keys[order_column]]

      collection.order("#{col[:column]} #{order_direction} NULLS #{order_direction == 'ASC' ? 'LAST' : 'FIRST'}")
    end

    def search(collection)
      search_terms.each do |name, search_term|
        next unless search_term.present?

        column = table_columns[name][:column]

        collection = collection.where(
          case table_columns[name][:type]
          when :string
            if (table_columns[name][:filter][:type].to_s == 'select' rescue false)
              "#{column} = '#{search_term}'"
            else
              "#{column} ILIKE '%#{search_term}%'"
            end
          when :integer
            "#{column} = '#{search_term}'"
          when :year
            "EXTRACT(YEAR FROM #{column}) = '#{search_term}'"
          when :boolean
            "#{column} = #{search_term}"
          else
            "#{column} = '#{search_term}'"
          end
        )
      end

      collection
    end

    def paginate(collection)
      collection.page(page).per(per_page)
    end

    def arrayize(collection)
      cols = table_columns

      collection.map do |obj|
        cols.map do |name, opts|
          (opts[:partial] ? render(:partial => opts[:partial], :formats => :html, :locals => {:datatable => self, opts[:partial_local] => obj}) : obj.send(name)) rescue ''
        end
      end
    end

  end
end

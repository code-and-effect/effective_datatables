module Effective
  module ActiveRecordDatatable
    def order(collection)
      col = table_columns[table_columns.keys[order_column]]

      collection.order("#{col[:column]} #{order_direction} NULLS #{order_direction == 'ASC' ? 'LAST' : 'FIRST'}")
    end

    def search(collection)
      search_terms.each do |name, search_term|
        if search_term.present?
          column_search = search_column(collection, table_columns[name], search_term)
          collection = column_search unless column_search.nil?
        end
      end
      collection
    end

    def search_column_with_defaults(collection, table_column, search_term)
      column = table_column[:column]

      collection.where(
        case table_column[:type]
        when :string
          if table_column[:filter][:type].to_s == 'select'
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

    def paginate(collection)
      collection.page(page).per(per_page)
    end

    def arrayize(collection)
      # We want to use the render :collection for each column that renders partials
      rendered = {}
      table_columns.each do |name, opts|
        if opts[:partial]
          rendered[name] = (render(
            :partial => opts[:partial], 
            :as => opts[:partial_local], 
            :collection => collection, 
            :formats => :html, 
            :locals => {:datatable => self},
            :spacer_template => '/effective/datatables/spacer_template',
          ) || '').split('EFFECTIVEDATATABLESSPACER')
        end
      end

      collection.each_with_index.map do |obj, index|
        table_columns.map do |name, opts|
          if opts[:partial]
            rendered[name][index]
          elsif opts[:block]
            @view.instance_exec(obj, collection, self, &opts[:block])
          elsif opts[:proc]
            @view.instance_exec(obj, collection, self, &opts[:proc])
          else
            obj.send(name) rescue ''
          end
        end
      end
    end

  end
end

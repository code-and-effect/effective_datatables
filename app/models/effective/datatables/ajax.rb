# This is extended as class level into Datatable

module Effective
  module Datatables
    module Ajax
      def order_name
        @order_name ||= begin
          if params[:order] && params[:columns]
            order_column_index = (params[:order].first[1][:column] rescue '0')
            (params[:columns][order_column_index] || {})[:name]
          elsif default_order.present?
            default_order.keys.first
          end || table_columns.keys.first
        end
      end

      def order_direction
        @order_direction ||= if params[:order].present?
          params[:order].first[1][:dir] == 'desc' ? 'DESC' : 'ASC'
        elsif default_order.present?
          default_order.values.first.to_s.downcase == 'desc' ? 'DESC' : 'ASC'
        else
          'ASC'
        end
      end

      def default_order
        self.class.instance_variable_get(:@default_order)
      end

      def default_entries
        @default_entries ||= begin
          entries = (self.class.instance_variable_get(:@default_entries).presence || EffectiveDatatables.default_entries)
          entries = -1 if entries.to_s.downcase == 'all'
          [10, 25, 50, 100, 250, 1000, -1].include?(entries) ? entries : 25
        end
      end

      def search_terms
        @search_terms ||= HashWithIndifferentAccess.new().tap do |terms|
          if params[:columns].present? # This is an AJAX request from the DataTable
            (params[:columns] || {}).each do |_, column|
              next if table_columns[column[:name]].blank? || (column[:search] || {})[:value].blank?

              terms[column[:name]] = column[:search][:value]
            end
          else # This is the initial render, and we have to apply default search terms only
            table_columns.each do |name, values|
              terms[name] = values[:filter][:selected] if values[:filter][:selected].present?
            end
          end
        end
      end

      # This is here so classes that inherit from Datatables can can override the specific where clauses on a search column
      def search_column(collection, table_column, search_term)
        if table_column[:array_column]
          array_tool.search_column_with_defaults(collection, table_column, search_term)
        else
          table_tool.search_column_with_defaults(collection, table_column, search_term)
        end
      end

      def per_page
        length = (params[:length].presence || default_entries).to_i

        if length == -1
          9999999
        elsif length > 0
          length
        else
          25
        end
      end

      def per_page=(length)
        case length
        when Integer
          params[:length] = length
        when :all
          params[:length] = -1
        end
      end

      def page
        params[:start].to_i / per_page + 1
      end

    end
  end
end

# This is extended as class level into Datatable

module Effective
  module EffectiveDatatable
    module Ajax

      # This is for the ColReorder plugin
      # It sends us a list of columns that are different than our table_columns order
      # So this method just returns an array of column names, as per ColReorder
      def display_table_columns
        return nil if params[:columns].blank?

        @display_table_columns ||= (
          {}.tap do |retval|
            params[:columns].each do |_, column|
              retval[column[:name]] = table_columns[column[:name]] # Same order as ColReordernow
              retval[column[:name]][:visible] = (column[:visible] == 'true') # As per ColVis
            end
          end
        )
      end

      def order_name
        @order_name ||= begin
          if params[:order] && params[:columns]
            order_by_column_index = (params[:order]['0'][:column] rescue '0')
            (params[:columns][order_by_column_index] || {})[:name]
          elsif @default_order.present?
            @default_order.keys.first
          end || table_columns.find { |col, opts| opts[:type] != :bulk_actions_column }.try(:first)
        end
      end

      def order_index
        (table_columns[order_name][:index] || 0) rescue 0
      end

      def order_direction
        @order_direction ||= if params[:order].present?
          params[:order]['0'][:dir] == 'desc' ? :desc : :asc
        elsif @default_order.present?
          @default_order.values.first.to_s.downcase == 'desc' ? :desc : :asc
        else
          :asc
        end
      end

      def display_entries
        @display_entries ||= begin
          entries = (@default_entries.presence || EffectiveDatatables.default_entries)
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

      def per_page
        return 9999999 if simple?

        length = (params[:length].presence || display_entries).to_i

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

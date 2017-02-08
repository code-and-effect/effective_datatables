# This is extended as class level into Datatable

module Effective
  module EffectiveDatatable
    module State

      def display_columns
        columns.select { |name, _| state[:visible][name] }
      end

      def display_length
        state[:length]
      end

      def order_direction
        state[:order_dir]
      end

      def order_index
        state[:order_index]
      end

      def order_name
        state[:order_name]
      end

      def search_terms
        state[:search]
      end

      def page
        state[:start].to_i / state[:length] + 1
      end

      def per_page
        state[:length]
      end

      private

      def initialize_state
        {
          attributes: attributes,
          length: nil,
          order_name: nil,
          order_dir: nil,
          order_index: nil,
          start: nil,
          search: {},
          visible: {}
        }
      end

      def load_state!
        if view.params[:draw] && view.params[:columns]  # This is an AJAX action, do what datatables says.
          load_ajax_state!
        elsif view.cookies[to_param].present?
          load_cookie_state!
        else
          load_default_state!
        end

      end

      def load_ajax_state!
        params = view.params

        state[:length] = params[:length].to_i
        state[:order_dir] = params[:order]['0'][:dir] == 'desc' ? :desc : :asc
        state[:order_index] = params[:order]['0'][:column].to_i
        state[:order_name] = columns.find { |name, opts| opts[:index] == state[:order_index] }.first

        state[:start] = params[:start].to_i

        state[:visible] = {}
        state[:search] = {}

        params[:columns].values.each do |params|
          name = params[:name].to_sym
          raise "unexpected column name: #{name}" unless columns.key?(name)

          state[:visible][name] = (params[:visible] == 'true')
          state[:search][name] = params[:search][:value] if params[:search][:value].present?
        end
      end

      def load_cookie_state!
      end

      def load_default_state!
        # Might already be set by DSL methods
        state[:length] ||= 25
        state[:order_dir] ||= :asc
        state[:order_name] ||= columns.first[0]

        # Must compute and apply defaults
        state[:order_index] = columns[order_name][:index]
        state[:start] = 0

        columns.each do |name, opts|
          state[:search][name] = opts[:filter][:selected] if opts[:filter][:selected]
          state[:visible][name] = opts[:visible]
        end
      end

    end
  end
end

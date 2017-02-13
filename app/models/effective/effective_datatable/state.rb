module Effective
  module EffectiveDatatable
    module State

      def scope
        state[:scope]
      end

      def filter
        state[:filter]
      end

      def display_length
        state[:length]
      end

      def display_start
        state[:start]
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

      # This is called first.  Our initial state is set.
      def initial_state
        {
          filter: {},
          length: 25,
          order_name: nil,
          order_dir: nil,
          order_index: nil,
          params: 0,
          scope: nil,
          start: 0,
          search: {},
          visible: {}
        }
      end

      def load_filters!
        state[:filter] = filters.inject({}) { |h, (name, opts)| h[name] = opts[:value]; h }
        state[:scope] = scopes.find { |_, opts| opts[:default] }.try(:first) || scopes.keys.first

        filter_params.each { |name, value| state[:filter][name] = parse_filter(filters[name], value) }
        state[:scope] = scope_param if scope_param
      end

      def load_state!
        if datatables_ajax_request?
          Rails.logger.info('AJAX')
          load_ajax_state!
        elsif cookie.present? && cookie[:state][:params] == params.length
          Rails.logger.info('COOKIE')
          load_cookie_state!
        else
          Rails.logger.info('DEFAULT')
          # Nothing to do for default state
        end
      end

      def load_ajax_state!
        state[:length] = params[:length].to_i
        state[:order_dir] = params[:order]['0'][:dir] == 'desc' ? :desc : :asc
        state[:order_index] = params[:order]['0'][:column].to_i

        state[:scope] = scopes.keys.find { |name| params[:scope] == name.to_s }
        state[:start] = params[:start].to_i

        state[:search] = {}
        state[:visible] = {}

        params[:columns].values.each do |params|
          name = params[:name].to_sym

          state[:search][name] = params[:search][:value] if params[:search][:value].present? # TODO deal with false/true/nil
          state[:visible][name] = (params[:visible] == 'true')
        end

        state[:filter] = {}

        params[:filter].each do |name, value|
          name = name.to_sym
          raise "unexpected filter name: #{name}" unless filters.key?(name)

          state[:filter][name] = parse_filter(filters[name], value)
        end

        state[:params] = cookie[:state][:params]
      end

      def load_cookie_state!
        @state = cookie[:state]
      end

      def load_columns!
        state[:order_dir] ||= :asc

        if order_index.present?
          state[:order_name] = columns.keys[order_index]
        else
          state[:order_name] ||= columns.find { |name, opts| opts[:sortable] }.first
          state[:order_index] = columns[order_name][:index]
        end

        if state[:search].blank?
          columns.each do |name, opts|
            state[:search][name] = opts[:search][:value] if opts[:search].key?(:value)
          end
        end

        columns.each do |name, opts|
          state[:visible][name] = opts[:visible] unless state[:visible].key?(name)
        end

        unless datatables_ajax_request?
          search_params.each { |name, value| state[:search][name] = value }
          state[:params] = params.length
        end

        state[:visible].delete_if { |name, _| columns.key?(name) == false }
        state[:search].delete_if { |name, _| columns.key?(name) == false }
      end
    end
  end
end

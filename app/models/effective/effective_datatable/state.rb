module Effective
  module EffectiveDatatable
    module State

      def scope
        state[:scope]
      end
      alias_method :current_scope, :scope
      alias_method :scopes, :scope

      def filter
        state[:filter]
      end
      alias_method :filters, :filter

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

      def search
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
          length: nil,
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
        state[:filter] = _filters.inject({}) { |h, (name, opts)| h[name] = opts[:value]; h }
        state[:scope] = _scopes.find { |_, opts| opts[:default] }.try(:first) || _scopes.keys.first
      end

      def load_filter_params!
        filter_params.each { |name, value| state[:filter][name] = parse_filter_value(_filters[name], value) }
        state[:scope] = scope_param if scope_param
      end

      def load_state!
        if datatables_ajax_request?
          load_ajax_state!
        elsif cookie.present? && cookie[:state][:params] == params.length
          load_cookie_state!
        else
          # Nothing to do for default state
        end

        load_filter_params! unless datatables_ajax_request?
      end

      def load_ajax_state!
        state[:length] = params[:length].to_i

        state[:order_dir] = (params[:order]['0'][:dir] == 'desc' ? :desc : :asc)
        state[:order_index] = params[:order]['0'][:column].to_i

        state[:scope] = _scopes.keys.find { |name| params[:scope] == name.to_s }
        state[:start] = params[:start].to_i

        state[:search] = {}
        state[:visible] = {}

        params[:columns].values.each do |params|
          name = params[:name].to_sym

          if params[:search][:value].present? && !['null'].include?(params[:search][:value])
            state[:search][name] = params[:search][:value]
          end

          state[:visible][name] = (params[:visible] == 'true')
        end

        state[:filter] = {}

        (params[:filter] || {}).each do |name, value|
          name = name.to_sym
          raise "unexpected filter name: #{name}" unless _filters.key?(name)

          state[:filter][name] = parse_filter_value(_filters[name], value)
        end

        state[:params] = cookie[:state][:params]
      end

      def load_cookie_state!
        @state = cookie[:state]
      end

      def load_columns!
        state[:length] ||= EffectiveDatatables.default_length


        if columns.present?
          if order_index.present?
            state[:order_name] = columns.keys[order_index]
            raise "invalid order index #{order_index}" unless columns.keys[order_index]
          else
            state[:order_name] ||= columns.find { |name, opts| opts[:sort] }.first
            raise "order column :#{order_name} must exist as a col or val" unless columns[order_name]

            state[:order_index] = columns[order_name][:index]
          end
        end

        # Set default order direction
        state[:order_dir] ||= ['_at', '_on', 'date'].any? { |str| order_name.to_s.end_with?(str) } ? :desc : :asc

        if state[:search].blank?
          columns.each do |name, opts|
            state[:search][name] = opts[:search][:value] if opts[:search].kind_of?(Hash) && opts[:search].key?(:value)
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

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

      def offset
        [(page - 1), 0].max * per_page
      end

      def page
        state[:start].to_i / state[:length] + 1
      end

      def per_page
        state[:length]
      end
      alias_method :limit, :per_page

      private

      # This is called first. Our initial state is set.
      def initial_state
        {
          attributes: {},
          filter: {},
          length: nil,
          order_name: nil,
          order_dir: nil,
          order_index: nil,
          params: 0,
          scope: nil,
          start: 0,
          search: {},
          vismask: nil,
          visible: {},
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

      def fill_empty_filters!
        state[:filter].each do |name, value|
          next unless (value.nil? && _filters[name][:required])
          state[:filter][name] = _filters[name][:value]
        end
      end

      def load_state!
        if datatables_ajax_request?
          load_filter_params!
          load_ajax_state!
        elsif cookie.present? && cookie[:params] == params.length
          load_cookie_state!
        else
          # Nothing to do for default state
        end

        load_filter_params! unless datatables_ajax_request?
        fill_empty_filters!
      end

      def load_ajax_state!
        state[:length] = params[:length].to_i

        if params[:order]
          state[:order_dir] = (params[:order]['0'][:dir] == 'desc' ? :desc : :asc)
          state[:order_index] = params[:order]['0'][:column].to_i
        end

        state[:scope] = _scopes.keys.find { |name| params[:scope] == name.to_s }
        state[:start] = params[:start].to_i

        state[:search] = {}
        state[:visible] = {}

        params[:columns].values.each do |params|
          name = (params[:name].include?('.') ? params[:name] : params[:name].to_sym)

          if params[:search][:value].present? && !['null'].include?(params[:search][:value])
            state[:search][name] = params[:search][:value]
          end

          state[:visible][name] = (params[:visible] == 'true')
        end

        (params[:filter] || {}).each do |name, value|
          name = name.to_sym
          raise "unexpected filter name: #{name}" unless _filters.key?(name)

          state[:filter][name] = parse_filter_value(_filters[name], value)
        end

        state[:params] = cookie[:params]
      end

      def load_cookie_state!
        @state = cookie
      end

      def load_columns!
        state[:length] ||= EffectiveDatatables.default_length

        (columns || {}).each_with_index { |(_, column), index| column[:index] = index }

        if columns.present?
          state[:order_name] = (
            if columns.key?(:_reorder)
              :_reorder
            elsif order_index.present?
              columns.keys[order_index]
            else
              columns.find { |name, opts| opts[:sort] }.first
            end
          )

          raise "order column :#{order_name} must exist as a col or val" unless columns[order_name]

          state[:order_index] = columns[order_name][:index]
        end

        # Set default order direction
        state[:order_dir] ||= ['_at', '_on', 'date'].any? { |str| order_name.to_s.end_with?(str) } ? :desc : :asc

        if state[:search].blank? && !datatables_ajax_request?
          columns.each do |name, opts|
            next unless opts[:search].kind_of?(Hash) && opts[:search].key?(:value)
            state[:search][name] = opts[:search][:value]
          end
        end

        # Load cookie bitmask
        if datatables_ajax_request?
          # Nothing to do
        elsif state[:vismask].kind_of?(Integer) # bitmask
          state[:visible] = {}
          columns.each { |name, opts| state[:visible][name] = (state[:vismask] & (2 ** opts[:index])) != 0 }
        else
          state[:visible] = {} unless state[:visible].kind_of?(Hash)
          columns.each { |name, opts| state[:visible][name] = opts[:visible] unless state[:visible].key?(name) }
        end

        unless datatables_ajax_request?
          search_params.each { |name, value| state[:search][name] = value }
          state[:params] = params.length
        end

        state[:visible].delete_if { |name, _| columns.key?(name) == false }
        state[:search].delete_if { |name, _| columns.key?(name) == false }
      end

      # The incoming value could be from the passed page params or from the AJAX request.
      # When we parse an incoming filter term for this filter.
      def parse_filter_value(filter, value)
        return filter[:parse].call(value) if filter[:parse]
        Effective::Attribute.new(filter[:value]).parse(value, name: filter[:name])
      end

    end
  end
end

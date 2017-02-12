module Effective
  module EffectiveDatatable
    module State

      def current_scope
        state[:scope]
      end

      def filters
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
        state[:order_index] || raise('no order index')
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

      def initial_state
        {
          filter: filterdefs.inject({}) { |h, (name, opts)| h[name] = opts[:value]; h },
          length: 25,
          order_name: nil,
          order_dir: nil,
          order_index: nil,
          params: 0,
          scope: scopes.find { |_, opts| opts[:default] }.try(:first) || scopes.keys.first,
          start: 0,
          search: {}, # {email: 'something@', user_id: 3}
          visible: {}
        }
      end

      def initialize_state!
        @state ||= initial_state

        if datatables_ajax_request?
          Rails.logger.info('AJAX')
          load_ajax_state!
        elsif cookie.present? && cookie[:state][:params] == search_params.length && cookie[:state][:visible].length == columns.length
          Rails.logger.info('COOKIE')
          load_cookie_state!
        else
          Rails.logger.info('DEFAULT')
          # Nothing to do in default state
        end

        view.state = state
      end

      def load_ajax_state!
        params = view.params

        state[:length] = params[:length].to_i
        state[:order_dir] = params[:order]['0'][:dir] == 'desc' ? :desc : :asc
        state[:order_index] = params[:order]['0'][:column].to_i

        state[:scope] = scopes.keys.find { |name| params['scope'] == name.to_s }
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
          raise "unexpected filter name: #{name}" unless filterdefs.key?(name)

          state[:filter][name] = parse_filter(filterdefs[name], value)
        end

        state[:params] = cookie[:state][:params]
      end

      def load_cookie_state!
        @state = cookie[:state]
      end

      def load_columns_state!
        # These 3 might already be set by DSL methods
        state[:order_dir] ||= :asc

        if order_index.present?
          state[:order_name] = columns.keys[order_index]
        else
          state[:order_name] ||= columns.find { |name, opts| opts[:sortable] }.first
          state[:order_index] = columns[order_name][:index]
        end

        if state[:visible].blank? && state[:search].blank?
          columns.each do |name, opts|
            state[:search][name] = opts[:filter][:selected] if opts[:filter].key?(:selected)
            state[:visible][name] = opts[:visible]
          end
        end

        # Now that we know about the columns, we can ensure only column name params are being set
        load_params_state!
      end

      # Overrides any state params set from the cookie
      def load_params_state!
        search_params.each { |name, value| state[:search][name] = value }
        state[:params] = search_params.length
      end

      def search_params
        @search_params ||= (
          {}.tap do |params|
            # TODO FIX search for id ID
            view.params.each { |name, value| name = name.to_sym; params[name] = value if (columns.key?(name) && name != :id) }
          end
        )
      end

    end
  end
end

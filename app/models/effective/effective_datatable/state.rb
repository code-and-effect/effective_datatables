module Effective
  module EffectiveDatatable
    module State

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

      def initial_state
        {
          length: nil,
          order_name: nil,
          order_dir: nil,
          order_index: nil,
          params: 0,
          start: nil,
          search: {}, # {email: 'something@', user_id: 3}
          visible: {}
        }
      end

      def initialize_state!
        if datatables_ajax_request?
          load_ajax_state!
        elsif cookie.present? && cookie[:state][:params] == search_params.length && cookie[:state][:visible].length == columns.length
          load_cookie_state!
          load_params_state!
        else
          load_default_state!
          load_params_state!
        end
      end

      def load_ajax_state!
        params = view.params

        state[:length] = params[:length].to_i
        state[:order_dir] = params[:order]['0'][:dir] == 'desc' ? :desc : :asc
        state[:order_index] = params[:order]['0'][:column].to_i
        state[:order_name] = columns.find { |name, opts| opts[:index] == state[:order_index] }.first

        state[:start] = params[:start].to_i

        state[:search] = {}
        state[:visible] = {}

        params[:columns].values.each do |params|
          name = params[:name].to_sym
          raise "unexpected column name: #{name}" unless columns.key?(name)

          state[:search][name] = params[:search][:value] if params[:search][:value].present? # TODO deal with false/true/nil
          state[:visible][name] = (params[:visible] == 'true')
        end

        state[:params] = cookie[:state][:params]
      end

      def load_cookie_state!
        @state = cookie[:state]
      end

      def load_default_state!
        # These 3 might already be set by DSL methods
        state[:length] ||= 25
        state[:order_dir] ||= :asc
        state[:order_name] ||= columns.find { |name, opts| opts[:sortable] }.first

        # Must compute and apply defaults
        state[:order_index] = columns[order_name][:index]
        state[:start] = 0

        columns.each do |name, opts|
          state[:search][name] = opts[:filter][:selected] if opts[:filter].key?(:selected)
          state[:visible][name] = opts[:visible]
        end
      end

      # Overrides any state params set from the cookie
      def load_params_state!
        search_params.each { |name, value| state[:search][name] = value }
        state[:params] = search_params.length
      end

      def search_params
        @search_params ||= (
          {}.tap do |params|
            view.params.each { |name, value| name = name.to_sym; params[name] = value if columns.key?(name) }
          end
        )
      end

    end
  end
end

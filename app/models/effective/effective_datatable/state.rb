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
          start: nil,
          search: {},
          visible: {}
        }
      end

      def load_state!
        if datatables_ajax_request?
          load_ajax_state!
          save_state!
        elsif state_cookie.present?
          load_saved_state!
        else
          load_default_state!
          save_state!
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

      def load_saved_state!
        state = Marshal.load(state_cookie)
        raise 'invalid cookie' unless state.kind_of?(Hash)
        @state = state
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

        # This parses the URL for any param passed searches
        view.params.each do |key, value|
          name = key.to_sym
          next unless columns.key?(name)

          state[:search][name] = value
        end
      end

      def save_state!
        view.cookies.signed[state_cookie_name] = Marshal.dump(state)
      end

      def state_cookie
        @state_cookie ||= view.cookies.signed[state_cookie_name]
      end

      def state_cookie_name
        @state_cookie_name ||= (
          uri = URI(view.request.referer || view.request.url)
          Base64.encode64(['state', to_param, uri.path, uri.query].join)
        )
      end

    end
  end
end

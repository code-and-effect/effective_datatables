module Effective
  module EffectiveDatatable
    module Params

      private

      def datatables_ajax_request?
        return @_datatables_ajax_request unless @_datatables_ajax_request.nil?

        @_datatables_ajax_request = (view.present? && view.params.key?(:draw) && view.params.key?(:columns))
      end

      def datatables_inline_request?
        return @_datatables_inline_request unless @_datatables_inline_request.nil?

        @_datatables_inline_request = (view.present? && view.params[:_datatable_id].to_s.split('-')[0...-1] == to_param.split('-')[0...-1])
      end

      def params
        return {} unless view.present?
        @params ||= {}.tap do |params|
          Rack::Utils.parse_query(URI(view.request.referer.presence || '/').query).each { |k, v| params[k.to_sym] = v }
          view.params.each { |k, v| params[k.to_sym] = v }
        end
      end

      def filter_params
        params.select { |name, value| _filters.key?(name.to_sym) && name != 'id' }
      end

      def scope_param
        params[:scope].to_sym if params.key?(:scope)
      end

      def search_params
        params.select do |name, value|
          columns.key?(name) && ![:id, :action].include?(name) && !value.kind_of?(Hash) && value.class.name != 'ActionController::Parameters'.freeze
        end
      end
    end
  end
end

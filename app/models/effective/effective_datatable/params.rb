module Effective
  module EffectiveDatatable
    module Params

      private

      def datatables_ajax_request?
        return @_datatables_ajax_request unless @_datatables_ajax_request.nil?

        @_datatables_ajax_request =
          (view && view.params[:draw] && view.params[:columns] && cookie_keys.include?(view.params[:cookie])) == true
      end

      def datatables_inline_request?
        return @_datatables_inline_request unless @_datatables_inline_request.nil?

        @_datatables_inline_request =
          (view && view.params[:_datatable_cookie] && cookie_keys.include?(view.params[:_datatable_cookie])) == true
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
          columns.key?(name) && (name != :id) && !value.kind_of?(Hash) && value.class.name != 'ActionController::Parameters'.freeze
        end
      end
    end
  end
end

# frozen_string_literal: true

module Effective
  module EffectiveDatatable
    module Params

      private

      def datatables_ajax_request?
        return @_datatables_ajax_request unless @_datatables_ajax_request.nil?
        return unless view.respond_to?(:params)

        @_datatables_ajax_request = view.params.present? && (view.params.key?(:draw) && view.params.key?(:columns))
      end

      def datatables_inline_request?
        return @_datatables_inline_request unless @_datatables_inline_request.nil?
        return unless view.respond_to?(:params)

        @_datatables_inline_request = view.params.present? && (view.params[:_datatable_id].to_s.split('-')[0...-1] == to_param.split('-')[0...-1])
      end

      def params
        return {} unless view.present?
        return view.rendered_params if view.respond_to?(:rendered_params)
        return {} unless view.respond_to?(:request) && view.request.present?

        @params ||= {}.tap do |params|
          Rack::Utils.parse_query(URI(view.request.referer.presence || '/').query).each { |k, v| params[k.to_sym] = v }
          view.params.each { |k, v| params[k.to_sym] = v }
        end
      end

      def filter_params
        params.select { |name, value| _filters.key?(name.to_sym) && name != 'id' }
      end

      def scope_param
        if params.key?(:scope)
          params[:scope].to_sym 
        elsif params.key?(:filters) && params[:filters].key?(:scope)
          params[:filters][:scope].to_sym 
        end
      end

      def search_params
        params.select do |name, value|
          columns.key?(name) && ![:id, :action].include?(name) && !value.kind_of?(Hash) && value.class.name != 'ActionController::Parameters'.freeze
        end
      end
    end
  end
end

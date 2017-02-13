module Effective
  module EffectiveDatatable
    module Params

      private

      def params
        return {} unless view.present?
        @params ||= {}.tap { |params| view.params.each { |k, v| params[k.to_sym] = v } }
      end

      def filter_params
        params.select { |name, value| filters.key?(name) }
      end

      def search_params
        params.select { |name, value| columns.key?(name) && name != :id } # TODO FIX search for id ID
      end

      def scope_param
        params[:scope].to_sym if params.key?(:scope)
      end

    end
  end
end

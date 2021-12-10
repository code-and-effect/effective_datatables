# frozen_string_literal: true

module Effective
  module EffectiveDatatable
    module Attributes

      private

      def assert_attributes!
        if datatables_ajax_request? || datatables_inline_request?
          raise 'expected attributes to be present' unless attributes.present?
        end
      end

      def load_attributes!
        return unless view.respond_to?(:controller_path)
        @attributes[:namespace] ||= view.controller_path.split('/')[0...-1].join('/')
      end

    end
  end
end

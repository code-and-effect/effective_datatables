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

      # Polymorphic shorthand attributes.
      # If you pass resource: User(1), it sets resource_id: 1, resource_type: 'User'
      def initial_attributes(attributes)
        return {} if attributes.blank?

        resources = attributes.select { |k, v| v.kind_of?(ActiveRecord::Base) }
        return attributes if resources.blank?

        retval = attributes.except(*resources.keys)

        resources.each do |k, resource|
          retval["#{k}_id".to_sym] = resource.id
          retval["#{k}_type".to_sym] = resource.class.name
        end

        retval
      end

    end
  end
end

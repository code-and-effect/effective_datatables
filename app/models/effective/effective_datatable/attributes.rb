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

      # Polymorphic shorthand attributes.
      # If you pass resource: User(1), it sets resource_id: 1, resource_type: 'User'
      def initial_attributes(attributes)
        return {} if attributes.blank?

        resources = attributes.select { |k, v| v.kind_of?(ActiveRecord::Base) }
        return attributes if resources.blank?

        retval = attributes.except(*resources.keys)

        resources.each do |k, resource|
          retval["#{k}_type".to_sym] = resource.class.name
          retval["#{k}_id".to_sym] = resource.id
        end

        retval
      end

      def load_attributes!
        return unless view.respond_to?(:controller_path)

        # Assign namespace based off controller path unless given
        @attributes[:namespace] ||= view.controller_path.split('/')[0...-1].join('/')
      end

    end
  end
end

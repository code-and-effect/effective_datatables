module Effective
  module EffectiveDatatable
    module Hooks

      # Called on the final collection after searching, ordering, arrayizing and formatting have been completed
      def finalize(collection) # Override me if you like
        collection
      end

      # The incoming value could be from the passed page params or from the AJAX request.
      # When we parse an incoming filter term for this filter.
      def parse_filter_value(filter, value)
        return filter[:parse].call(value) if filter[:parse]
        Effective::Attribute.new(filter[:value]).parse(value, name: filter[:name])
      end

    end
  end
end

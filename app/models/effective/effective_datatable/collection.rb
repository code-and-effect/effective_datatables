module Effective
  module EffectiveDatatable
    module Collection

      # Used for authorization.  We authorize with authorized?(:index, collection_class)
      def collection_class
        @collection_class  # Will be either User/Post/etc or Array
      end

      def active_record_collection?
        @active_record_collection == true
      end

      def array_collection?
        @array_collection == true
      end

      private

      def load_collection!
        raise 'No collection defined. Please add a collection with collection do ... end' if collection.nil?

        @collection_class = (collection.respond_to?(:klass) ? collection.klass : self.class)
        @active_record_collection = (collection.ancestors.include?(ActiveRecord::Base) rescue false)
        @array_collection = (collection.kind_of?(Array) && (collection.length == 0 || collection.first.kind_of?(Array)))

        unless active_record_collection? || array_collection?
          raise "Unsupported collection type. Expecting an ActiveRecord class, ActiveRecord relation, or an Array of Arrays [[1, 'something'], [2, 'something else']]"
        end
      end

    end
  end
end

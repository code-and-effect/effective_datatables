# frozen_string_literal: true

module Effective
  module EffectiveDatatable
    module Collection

      # Used for authorization.  We authorize with authorized?(:index, collection_class)
      def collection_class
        @collection_class  # Will be either User/Post/etc or Array
      end

      # User.all
      def active_record_collection?
        @active_record_collection == true
      end

      # [User<1>, User<2>, Post<1>, Page<3>]
      def active_record_array_collection?
        @active_record_array_collection == true
      end

      def active_record_polymorphic_array_collection?
        return false unless active_record_array_collection?
        return @active_record_polymorphic_array_collection unless @active_record_polymorphic_array_collection.nil?
        @active_record_polymorphic_array_collection = collection.map { |obj| obj.class }.uniq.length > 1
      end

      # [[1, 'foo'], [2, 'bar']]
      def array_collection?
        @array_collection == true
      end

      private

      def load_collection!
        raise 'No collection defined. Please add a collection with collection do ... end' if collection.nil?

        @collection_class = (collection.respond_to?(:klass) ? collection.klass : self.class)

        @active_record_collection = (collection.ancestors.include?(ActiveRecord::Base) rescue false)
        @active_record_array_collection = collection.kind_of?(Array) && collection.present? && collection.first.kind_of?(ActiveRecord::Base)
        @array_collection = collection.kind_of?(Array) && (collection.blank? || collection.first.kind_of?(Array))

        unless active_record_collection? || active_record_array_collection? || array_collection?
          raise "Unsupported collection. Expecting an ActiveRecord relation, an Array of ActiveRecord objects, or an Array of Arrays [[1, 'foo'], [2, 'bar']]"
        end

        _scopes.each do |scope, _|
          raise "invalid scope: :#{scope}. The collection must respond to :#{scope}" unless collection.respond_to?(scope)
        end
      end

    end
  end
end

# frozen_string_literal: true

module Effective
  module EffectiveDatatable
    module Resource
      AGGREGATE_SQL_FUNCTIONS = ['ARRAY_AGG(', 'AVG(', 'COUNT(', 'MAX(', 'MIN(', 'STRING_AGG(', 'SUM(']

      def admin_namespace?
        [:admin, 'admin'].include?(controller_namespace)
      end

      def controller_namespace
        @attributes[:namespace]
      end

      def association_macros
        [:belongs_to, :belongs_to_polymorphic, :has_many, :has_and_belongs_to_many, :has_one]
      end

      private

      # This looks at all the columns and figures out the as:
      def load_resource!
        load_effective_resource!

        load_active_record_collection!
        load_active_record_array_collection!
        load_array_collection!

        load_resource_columns!
        load_resource_belongs_tos!
        load_resource_search!
      end

      def load_effective_resource!
        @effective_resource ||= if active_record_collection?
          Effective::Resource.new(collection_class, namespace: controller_namespace)
        end
      end

      def load_active_record_collection!
        return unless active_record_collection?

        columns.each do |name, opts|
          # col 'comments.title'
          if name.kind_of?(String) && name.include?('.')
            raise "invalid datatables column '#{name}'. the joined syntax only supports one dot." if name.scan(/\./).count > 1

            (associated, field) = name.split('.').first(2)

            unless association_macros.include?(effective_resource.sql_type(associated))
              raise "invalid datatables column '#{name}'. unable to find '#{name.split('.').first}' association on '#{effective_resource}'."
            end

            joins_values = (collection.joins_values + collection.left_outer_joins_values)

            unless joins_values.include?(associated.to_sym)
              raise "your datatables collection must .joins(:#{associated}) or .left_outer_joins(:#{associated}) to work with the joined syntax"
            end

            opts[:resource] = Effective::Resource.new(effective_resource.associated(associated), namespace: controller_namespace)

            if opts[:resource].column(field)
              opts[:as] ||= opts[:resource].sql_type(field)
              opts[:as] = :integer if opts[:resource].sql_type(field) == :belongs_to && field.end_with?('_id')
              opts[:sql_column] = opts[:resource].sql_column(field) if opts[:sql_column].nil?

              opts[:resource].sort_column = field
              opts[:resource].search_columns = field
            end

            opts[:resource_field] = field

            next
          end

          # Regular fields
          opts[:as] ||= effective_resource.sql_type(name)
          opts[:sql_column] = effective_resource.sql_column(name) if opts[:sql_column].nil?

          case opts[:as]
          when *association_macros
            opts[:resource] ||= Effective::Resource.new(effective_resource.associated(name), namespace: controller_namespace)
            opts[:sql_column] = name if opts[:sql_column].nil?
          when Class
            if opts[:as].ancestors.include?(ActiveRecord::Base)
              opts[:resource] = Effective::Resource.new(opts[:as], namespace: controller_namespace)
              opts[:as] = :resource
              opts[:sql_column] = name if opts[:sql_column].nil?
            end
          when :effective_addresses
            opts[:resource] = Effective::Resource.new(effective_resource.associated(name), namespace: controller_namespace)
            opts[:sql_column] = :effective_addresses
          when :effective_roles
            opts[:sql_column] = :effective_roles
          when :active_storage
            opts[:sql_column] = :active_storage
          when :string  # This is the fallback
            # Anything that doesn't belong to the model or the sql table, we assume is a SELECT SUM|AVG|RANK() as fancy
            opts[:sql_as_column] = true if (effective_resource.table && effective_resource.column(name).blank?)
          end

          if opts[:sql_column].present?
            sql_column = opts[:sql_column].to_s
            opts[:sql_as_column] = true if AGGREGATE_SQL_FUNCTIONS.any? { |str| sql_column.start_with?(str) }
          end

        end
      end

      def load_active_record_array_collection!
        return unless active_record_array_collection?
      end

      def load_array_collection!
        return unless array_collection?

        row = collection.first

        columns.each do |name, opts|
          if opts[:as].kind_of?(Class) && opts[:as].ancestors.include?(ActiveRecord::Base)
            opts[:resource] = Effective::Resource.new(opts[:as], namespace: controller_namespace)
            opts[:as] = :resource
          elsif opts[:as] == nil && row.present?
            if (value = Array(row[opts[:index]]).first).kind_of?(ActiveRecord::Base)
              opts[:resource] = Effective::Resource.new(value, namespace: controller_namespace)
              opts[:as] = :resource
            end
          end
        end
      end

      def load_resource_columns!
        columns.each do |name, opts|
          opts[:as] ||= :string
          opts[:as] = :email if (opts[:as] == :string && name.to_s.end_with?('email'))

          if opts[:action]
            opts[:resource] ||= effective_resource
          end

          if opts[:resource] && !opts[:resource_field] && opts[:as] != :effective_addresses
            opts[:partial] ||= '/effective/datatables/resource_column'
          end

          if opts[:as] == :active_storage
            opts[:partial] ||= '/effective/datatables/active_storage_column'
          end

          opts[:col_class] = [
            "col-#{opts[:as]}",
            "col-#{name.to_s.parameterize}",
            ('colvis-default' if opts[:visible]),
            opts[:col_class].presence
          ].compact.join(' ')
        end
      end

      def load_resource_search!
        columns.each do |name, opts|
          # Normalize the given opts[:search] into a Hash
          # Take special note of the opts[:search] as we need to collapse it when an ActiveRecord::Relation
          case opts[:search]
          when false
            opts[:search] = { as: :null }; next
          when Symbol
            opts[:search] = { as: opts[:search] }
          when Array, ActiveRecord::Relation
            opts[:search] = { as: :select, collection: opts[:search] }
          when Hash
            # Nothing
          else
            raise "column #{name} unexpected search value"
          end

          # Now lets deal with the opts[:search] hash itself
          search = opts[:search]

          # Parameterize collection
          if search[:collection].kind_of?(ActiveRecord::Relation)
            search[:collection] = search[:collection].map { |obj| [obj.to_s, obj.id] }
          elsif search[:collection].kind_of?(Array) && search[:collection].first.kind_of?(ActiveRecord::Base)
            search[:collection] = search[:collection].map { |obj| [obj.to_s, obj.id] }
          elsif search[:collection].kind_of?(Array)
            search[:collection] = search[:collection]
          end

          search[:as] ||= :select if search.key?(:collection)
          search[:value] ||= search.delete(:selected) if search.key?(:selected)

          # Merge with defaults
          search_resource = [opts[:resource], effective_resource, fallback_effective_resource].compact
          search_resource = search_resource.find { |res| res.klass.present? } || search_resource.first

          # Assign search collections from effective_resources
          if search[:as] == :string
            # Nothing to do. We're just a string search.
          elsif search[:as] == :select && search[:collection].kind_of?(Array)
            # Nothing to do. We already loaded the custom parameterized collection above.
          elsif array_collection? && opts[:resource].present?
            # Assigns { as: :select, collection: [...] }
            search.reverse_merge!(search_resource.search_form_field(name, collection.first[opts[:index]]))
          else
            # Load the defaults from effective_resources
            # Assigns { as: :string } or { as: :select, collection: [...] }
            search.reverse_merge!(search_resource.search_form_field(name, opts[:as]))
          end

          # Assign default search operation
          search[:operation] ||= search.delete(:op)
          search[:operation] ||= :matches if search[:fuzzy]
          search[:operation] ||= :eq if search[:as] == :select
          search[:operation] ||= search_resource.sql_operation(name, as: opts[:as])

          # Assign default include_null
          if search[:as] == :select && !search.key?(:include_null)
            search[:include_null] = true
          end
        end
      end

      def load_resource_belongs_tos!
        return unless active_record_collection?
        return unless @_collection_apply_belongs_to

        changed = attributes.select do |attribute, value|
          attribute = attribute.to_s
          next unless attribute.ends_with?('_id')

          associated = attribute.gsub(/_id\z/, '').to_sym  # Replace last _id

          next unless columns[associated]

          if columns[associated][:as] == :belongs_to
            unless @_collection.where_values_hash.include?(attribute)
              @_collection = @_collection.where(attribute => value)
            end

            columns.delete(associated)
          elsif columns[associated][:as] == :belongs_to_polymorphic
            associated_type = attributes["#{associated}_type".to_sym] || raise("Expected #{associated}_type attribute to be present when #{associated}_id is present on a polymorphic belongs to")

            unless @_collection.where_values_hash.include?(attribute) || @_collection.where_values_hash.include?("#{associated}_type")
              @_collection = @_collection.where(attribute => value).where("#{associated}_type" => associated_type)
            end

            columns.delete(associated)
          end

        end.present?

        load_columns! if changed
      end

    end
  end
end

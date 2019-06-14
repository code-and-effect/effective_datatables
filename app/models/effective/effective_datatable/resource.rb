module Effective
  module EffectiveDatatable
    module Resource
      AGGREGATE_SQL_FUNCTIONS = ['ARRAY_AGG(', 'AVG(', 'COUNT(', 'MAX(', 'MIN(', 'STRING_AGG(', 'SUM(']

      def admin_namespace?
        controller_namespace == 'admin'
      end

      def controller_namespace
        @attributes[:namespace]
      end

      private

      # This looks at all the columns and figures out the as:
      def load_resource!
        @resource = Effective::Resource.new(collection_class, namespace: controller_namespace)

        if active_record_collection?
          columns.each do |name, opts|

            # col 'comments.title'
            if name.kind_of?(String) && name.include?('.')
              raise "invalid datatables column '#{name}'. the joined syntax only supports one dot." if name.scan(/\./).count > 1

              (associated, field) = name.split('.').first(2)

              unless resource.macros.include?(resource.sql_type(associated))
                raise "invalid datatables column '#{name}'. unable to find '#{name.split('.').first}' association on '#{resource}'."
              end

              joins_values = (collection.joins_values + collection.left_outer_joins_values)

              unless joins_values.include?(associated.to_sym)
                raise "your datatables collection must .joins(:#{associated}) or .left_outer_joins(:#{associated}) to work with the joined syntax"
              end

              opts[:resource] = Effective::Resource.new(resource.associated(associated), namespace: controller_namespace)

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
            opts[:as] ||= resource.sql_type(name)
            opts[:sql_column] = resource.sql_column(name) if opts[:sql_column].nil?

            case opts[:as]
            when *resource.macros
              opts[:resource] ||= Effective::Resource.new(resource.associated(name), namespace: controller_namespace)
              opts[:sql_column] = name if opts[:sql_column].nil?
            when Class
              if opts[:as].ancestors.include?(ActiveRecord::Base)
                opts[:resource] = Effective::Resource.new(opts[:as], namespace: controller_namespace)
                opts[:as] = :resource
                opts[:sql_column] = name if opts[:sql_column].nil?
              end
            when :effective_addresses
              opts[:resource] = Effective::Resource.new(resource.associated(name), namespace: controller_namespace)
              opts[:sql_column] = :effective_addresses
            when :effective_roles
              opts[:sql_column] = :effective_roles
            when :string  # This is the fallback
              # Anything that doesn't belong to the model or the sql table, we assume is a SELECT SUM|AVG|RANK() as fancy
              opts[:sql_as_column] = true if (resource.table && resource.column(name).blank?)
            end

            if opts[:sql_column].present? && AGGREGATE_SQL_FUNCTIONS.any? { |str| opts[:sql_column].to_s.start_with?(str) }
              opts[:sql_as_column] = true
            end
          end
        end

        if array_collection?
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

        columns.each do |name, opts|
          opts[:as] ||= :string
          opts[:as] = :email if (opts[:as] == :string && name.to_s.end_with?('email'))

          if opts[:action]
            opts[:resource] ||= resource
          end

          if opts[:resource] && !opts[:resource_field] && opts[:as] != :effective_addresses
            opts[:partial] ||= '/effective/datatables/resource_column'
          end

          opts[:col_class] = [
            "col-#{opts[:as]}",
            "col-#{name.to_s.parameterize}",
            ("colvis-default" if opts[:visible]),
            opts[:col_class].presence
          ].compact.join(' ')
        end
      end

      def load_resource_search!
        columns.each do |name, opts|

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

          search = opts[:search]

          if search[:collection].kind_of?(ActiveRecord::Relation)
            search[:collection] = search[:collection].map { |obj| [obj.to_s, obj.to_param] }
          elsif search[:collection].kind_of?(Array) && search[:collection].first.kind_of?(ActiveRecord::Base)
            search[:collection] = search[:collection].map { |obj| [obj.to_s, obj.to_param] }
          elsif search[:collection].kind_of?(Array)
            search[:collection].each { |obj| obj[1] = 'nil' if obj[1] == nil }
          elsif search[:collection].kind_of?(Hash)
            search[:collection].each { |k, v| search[:collection][k] = 'nil' if v == nil }
          end

          search[:value] ||= search.delete(:selected) if search.key?(:selected)

          search[:as] ||= :select if search.key?(:collection)

          search[:fuzzy] = true unless search.key?(:fuzzy)

          if array_collection? && opts[:resource].present?
            search.reverse_merge!(resource.search_form_field(name, collection.first[opts[:index]]))
          elsif search[:as] == :select && search.key?(:collection)
            # No Action
          elsif search[:as] != :string
            search.reverse_merge!(resource.search_form_field(name, opts[:as]))
          end

          # Assign default include_null
          if search[:as] == :select && !search.key?(:include_null)
            search[:include_null] = true
          end
        end
      end

      def apply_belongs_to_attributes!
        return unless active_record_collection?

        changed = attributes.select do |attribute, value|
          attribute = attribute.to_s
          next unless attribute.ends_with?('_id')

          associated = attribute.gsub(/_id\z/, '').to_sym  # Replace last _id

          next unless columns[associated]

          if columns[associated][:as] == :belongs_to
            @_collection = @_collection.where(attribute => value)
            columns.delete(associated)
          elsif columns[associated][:as] == :belongs_to_polymorphic
            associated_type = attributes["#{associated}_type".to_sym] || raise("Expected #{associated}_type attribute to be present when #{associated}_id is present on a polymorphic belongs to")

            @_collection = @_collection.where(attribute => value).where("#{associated}_type" => associated_type)
            columns.delete(associated)
          end

        end.present?

        load_columns! if changed
      end

    end
  end
end

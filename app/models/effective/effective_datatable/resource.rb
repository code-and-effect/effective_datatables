module Effective
  module EffectiveDatatable
    module Resource

      def admin_namespace?
        controller_namespace == 'admin'
      end

      def controller_namespace
        @attributes[:_n]
      end

      private

      # This looks at all the columns and figures out the as:
      def load_resource!
        @resource = Effective::Resource.new(collection_class, namespace: controller_namespace)

        if active_record_collection?
          columns.each do |name, opts|
            opts[:as] ||= resource.sql_type(name)
            opts[:sql_column] = (resource.sql_column(name) || false) if opts[:sql_column].nil?

            case opts[:as]
            when *resource.macros
              opts[:resource] = Effective::Resource.new(resource.associated(name), namespace: controller_namespace)
              opts[:sql_column] ||= name
            when Class
              if opts[:as].ancestors.include?(ActiveRecord::Base)
                opts[:resource] = Effective::Resource.new(opts[:as], namespace: controller_namespace)
                opts[:as] = :resource
                opts[:sql_column] ||= name
              end
            when :effective_addresses
              opts[:resource] = Effective::Resource.new(resource.associated(name), namespace: controller_namespace)
              opts[:sql_column] = :effective_addresses
            when :effective_roles
              opts[:sql_column] = :effective_roles
            when :string  # This is the fallback
              # Anything that doesn't belong to the model or the sql table, we assume is a SELECT SUM|AVG|RANK() as fancy
              if (resource.table && resource.column(name).blank?)
                opts[:sql_as_column] = true
              end
            end
          end
        end

        if array_collection?
          row = collection.first

          columns.each do |name, opts|
            if opts[:as].kind_of?(Class) && opts[:as].ancestors.include?(ActiveRecord::Base)
              opts[:resource] = Effective::Resource.new(opts[:as], namespace: controller_namespace)
              opts[:as] = :resource
            elsif opts[:as] == nil
              if (value = Array(row[opts[:index]]).first).kind_of?(ActiveRecord::Base)
                opts[:resource] = Effective::Resource.new(value, namespace: controller_namespace)
                opts[:as] = :resource
              end
            end
          end
        end

        columns.each do |name, opts|
          opts[:as] ||= :string
          opts[:as] = :email if (opts[:as] == :string && name == :email)

          opts[:partial] ||= '/effective/datatables/resource_column' if (opts[:resource] && opts[:as] != :effective_addresses)

          opts[:col_class] = "col-#{opts[:as]} col-#{name.to_s.parameterize} #{opts[:col_class]}".strip
        end

        load_resource_search!
      end

      def load_resource_search!
        columns.each do |name, opts|

          case opts[:search]
          when false
            opts[:search] = { as: :null }; next
          when Symbol
            opts[:search] = { as: opts[:search] }
          when Array, ActiveRecord::Relation
            opts[:search] = { collection: opts[:search] }
          end

          search = opts[:search]

          if search[:collection].kind_of?(ActiveRecord::Relation)
            search[:collection] = search[:collection].map { |obj| [obj.to_s, obj.to_param] }
          elsif search[:collection].kind_of?(Array)
            search[:collection].each { |obj| obj[1] = 'nil' if obj[1] == nil }
          end

          search[:as] ||= :select if (search.key?(:collection) && opts[:as] != :belongs_to_polymorphic)
          search[:fuzzy] = true unless search.key?(:fuzzy)

          if array_collection? && opts[:resource].present?
            search.reverse_merge!(resource.search_form_field(name, collection.first[opts[:index]]))
          else
            search.reverse_merge!(resource.search_form_field(name, opts[:as]))
          end
        end
      end
    end
  end
end

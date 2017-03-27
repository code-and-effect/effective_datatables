module Effective
  module EffectiveDatatable
    module Resource

      private

      def controller_namespace
        @attributes[:controller_namespace]
      end

      # This looks at all the columns and figures out the as:
      def load_resource!
        @resource = Effective::Resource.new([controller_namespace, collection_class.name].compact.join('/'))

        if active_record_collection?
          columns.each do |name, opts|
            opts[:as] ||= resource.sql_type(name)
            opts[:sql_column] = (resource.sql_column(name) || false) if opts[:sql_column].nil?

            case opts[:as]
            when *resource.macros
              opts[:resource] = Effective::Resource.new(resource.associated(name))
            when Class
              if opts[:as].ancestors.include?(ActiveRecord::Base)
                opts[:resource] = Effective::Resource.new(opts[:as])
                opts[:as] = :resource
              end
            when :effective_roles
              opts[:sql_column] = :effective_roles
            when :string  # This is the fallback
              # Anything that doesn't belong to the model or the sql table, we assume is a SELECT SUM|AVG|RANK() as fancy
              if (resource.table && resource.column(name).blank?)
                opts[:sql_as_column] = true
                opts[:sql_column] = name
              end
            end
          end
        end

        if array_collection?
          row = collection.first

          columns.each do |name, opts|
            if opts[:as].kind_of?(Class) && opts[:as].ancestors.include?(ActiveRecord::Base)
              opts[:resource] = Effective::Resource.new(opts[:as])
              opts[:as] = :resource
            elsif opts[:as] == nil
              if (value = Array(row[opts[:index]]).first).kind_of?(ActiveRecord::Base)
                opts[:resource] = Effective::Resource.new(value)
                opts[:as] = :resource
              end
            end
          end
        end

        columns.each do |name, opts|
          opts[:as] ||= :string
          opts[:as] = :email if (opts[:as] == :string && name == :email)

          opts[:partial] ||= '/effective/datatables/resource_column' if opts[:resource]

          opts[:col_class] = "col-#{opts[:as]} col-#{name.to_s.parameterize} #{opts[:col_class]}".strip
        end

        load_resource_search!
      end

      def load_resource_search!
        columns.each do |name, opts|
          search = opts[:search]

          if search == false
            opts[:search] = { as: :null }; next
          elsif search.kind_of?(Symbol)
            opts[:search] = { as: search }
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

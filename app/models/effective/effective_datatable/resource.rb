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
              opts[:partial] ||= '/effective/datatables/resource_column'
            when :effective_roles
              # Nothing
            else
              # Anything that doesn't belong to the model or the sql table, we assume is a SELECT SUM|AVG|RANK() as fancy
              opts[:sql_as_column] = true if (resource.table && resource.column(name).blank?)
            end
          end
        end

        if array_collection?
          row = collection.first

          columns.each do |name, opts|
            next if (opts[:as] || :resource) != :resource

            if row[opts[:index]].kind_of?(ActiveRecord::Base)
              opts[:resource] = Effective::Resource.new(row[opts[:index]])
              opts[:partial] ||= '/effective/datatables/resource_column'
            end
          end
        end

        columns.each do |name, opts|
          opts[:as] ||= :string
          opts[:col_class] = "col-#{opts[:as]} col-#{name.to_s.parameterize} #{opts[:col_class]}".strip
        end

        load_resource_search!
      end

      def load_resource_search!
        columns.each do |name, opts|
          search = opts[:search]

          if search == false
            opts[:search] = { as: :null }; next
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

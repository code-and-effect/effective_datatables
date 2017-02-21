module Effective
  module EffectiveDatatable
    module Resource

      private

      # This looks at all the columns and figures out the as:
      def load_resource!
        @resource = Effective::Resource.new(collection)

        if active_record_collection?
          columns.each do |name, opts|
            opts[:as] ||= resource.sql_type(name)
            opts[:sql_column] ||= (resource.sql_column(name) || name)

            unless [:belongs_to, :belongs_to_polymorphic, :has_and_belongs_to_many, :has_many, :has_one, :effective_addresses, :effective_roles].include?(opts[:as])
              opts[:sql_as_column] = true if (resource.table && resource.column(name).blank? && opts[:array_column] != true)
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
          #search[:sql_operation] = :having if ['SUM(', 'COUNT(', 'MAX(', 'MIN(', 'AVG('].any? { |str| (opts[:sql_column] || '').to_s.include?(str) }

          search.reverse_merge!(resource.search_form_field(name, opts[:as]))
        end
      end
    end
  end
end

module Effective
  module EffectiveDatatable
    module Resource

      private

      # This looks at all the columns and figures out the as:
      def load_resource!
        if active_record_collection?
          @resource = Effective::Resource.new(collection_class)

          columns.each do |name, opts|
            opts[:as] ||= resource.sql_type(name)
            opts[:sql_column] ||= (resource.sql_column(name) || name)
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
            opts[:search] = {as: :null}; next
          end

          search[:as] ||= :select if (search.key?(:collection) && opts[:as] != :belongs_to_polymorphic)
          search[:fuzzy] = true unless search.key?(:fuzzy)
          search[:sql_operation] = :having if ['SUM(', 'COUNT(', 'MAX(', 'MIN(', 'AVG('].any? { |str| (opts[:sql_column] || '').include?(str) }

          opts[:search] = search.reverse_merge(
            case opts[:as]
            when :belongs_to
              { as: :select }.merge(association_search_collection(resource.belongs_to(name)))
            when :belongs_to_polymorphic
              { as: :grouped_select, polymorphic: true, collection: nil}
            when :has_and_belongs_to_many
              { as: :select }.merge(association_search_collection(resource.has_and_belongs_to_many(name)))
            when :has_many
              { as: :select, multiple: true }.merge(association_search_collection(resource.has_many(name)))
            when :has_one
              { as: :select, multiple: true }.merge(association_search_collection(resource.has_one(name)))
            when :effective_addresses
              { as: :string }
            when :effective_roles
              { as: :select, collection: EffectiveRoles.roles }
            when :effective_obfuscation
              { as: :effective_obfuscation }
            when :boolean
              { as: :boolean, collection: [['true', true], ['false', false]] }
            when :datetime
              { as: :datetime }
            when :date
              { as: :date }
            when :integer
              { as: :number }
            else
              { as: :string }
            end
          )
        end
      end

      private

      def association_search_collection(association, max_id = 500)
        res = Effective::Resource.new(association)

        if res.max_id > max_id
          {as: :string}
        else
          if res.klass.unscoped.respond_to?(:datatables_filter)
            {collection: res.klass.datatables_filter}
          elsif res.klass.unscoped.respond_to?(:sorted)
            {collection: res.klass.sorted}
          else
            {collection: res.klass.all.map { |obj| [obj.to_s, obj.to_param] }.sort { |x, y| x[0] <=> y[0] }}
          end
        end
      end

    end
  end
end

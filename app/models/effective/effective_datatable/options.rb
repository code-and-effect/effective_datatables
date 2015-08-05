# This is extended as class level into Datatable

module Effective
  module EffectiveDatatable
    module Options

      def initialize_options
        @table_columns = initialize_column_options(@table_columns)
      end

      protected

      def initialize_column_options(cols)
        sql_table = (collection.table rescue nil)

        # Here we identify all belongs_to associations and build up a Hash like:
        # {user: {foreign_key: 'user_id', klass: User}, order: {foreign_key: 'order_id', klass: Effective::Order}}
        belong_tos = (collection.klass.reflect_on_all_associations(:belongs_to) rescue []).inject({}) do |retval, bt|
          next if bt.options[:polymorphic]

          klass = bt.klass || (bt.foreign_type.sub('_type', '').classify.constantize rescue nil)
          retval[bt.name.to_s] = {foreign_key: bt.foreign_key, klass: klass} if bt.foreign_key.present? && klass.present?

          retval
        end

        # has_manys
        has_manys = (collection.klass.reflect_on_all_associations(:has_many) rescue []).inject({}) do |retval, hm|
          klass = hm.klass || (hm.build_association({}).class)
          retval[hm.name.to_s] = {klass: klass}
          retval
        end

        table_columns = cols.each_with_index do |(name, _), index|
          # If this is a belongs_to, add an :if clause specifying a collection scope if
          if belong_tos.key?(name)
            cols[name][:if] ||= Proc.new { attributes[belong_tos[name][:foreign_key]].blank? }
          end

          sql_column = (collection.columns rescue []).find do |column|
            column.name == name.to_s || (belong_tos.key?(name) && column.name == belong_tos[name][:foreign_key])
          end

          cols[name][:array_column] ||= false
          cols[name][:array_index] = index # The index of this column in the collection, regardless of hidden table_columns
          cols[name][:name] ||= name
          cols[name][:label] ||= name.titleize
          cols[name][:column] ||= (sql_table && sql_column) ? "\"#{sql_table.name}\".\"#{sql_column.name}\"" : name
          cols[name][:width] ||= nil
          cols[name][:sortable] = true if cols[name][:sortable].nil?
          cols[name][:visible] = true if cols[name][:visible].nil?

          # Type
          cols[name][:type] ||= (
            if belong_tos.key?(name)
              :belongs_to
            elsif has_manys.key?(name)
              :has_many
            elsif sql_column.try(:type).present?
              sql_column.type
            else
              :string # When in doubt
            end
          )

          cols[name][:class] = "col-#{cols[name][:type]} col-#{name} #{cols[name][:class]}".strip

          # HasMany
          if cols[name][:type] == :has_many
            cols[name][:sortable] = false
          end

          # EffectiveObfuscation
          if name == 'id' && defined?(EffectiveObfuscation) && collection.respond_to?(:deobfuscate)
            cols[name][:sortable] = false
            cols[name][:type] = :obfuscated_id
          end

          # EffectiveRoles, if you do table_column :roles, everything just works
          if name == 'roles' && defined?(EffectiveRoles) && collection.respond_to?(:with_role)
            cols[name][:sortable] = true
            cols[name][:column] = sql_table.present? ? "\"#{sql_table.name}\".\"roles_mask\"" : name
            cols[name][:type] = :effective_roles
          end

          if sql_table.present? && sql_column.blank? # This is a SELECT AS column
            cols[name][:sql_as_column] = true
          end

          cols[name][:filter] = initialize_table_column_filter(cols[name][:filter], cols[name][:type], belong_tos[name], has_manys[name])

          if cols[name][:partial]
            cols[name][:partial_local] ||= (sql_table.try(:name) || cols[name][:partial].split('/').last(2).first.presence || 'obj').singularize.to_sym
          end
        end

        # After everything is initialized
        # Compute any col[:if] and assign an index
        table_columns.select do |_, col|
          col[:if] == nil || (col[:if].respond_to?(:call) ? (view || self).instance_exec(&col[:if]) : col[:if])
        end.each_with_index { |(_, col), index| col[:index] = index }

      end

      def initialize_table_column_filter(filter, col_type, belongs_to, has_many)
        return {type: :null} if filter == false

        filter = {type: filter.to_sym} if filter.kind_of?(String)
        filter = {} unless filter.kind_of?(Hash)

        # This is a fix for passing filter[:selected] == false, it needs to be 'false'
        filter[:selected] = filter[:selected].to_s unless filter[:selected].nil?

        case col_type
        when :belongs_to
          {
            type: :select,
            values: Proc.new { belongs_to[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[1] <=> y[1] } }
          }
        when :has_many
          {
            type: :select,
            multiple: true,
            values: Proc.new { has_many[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[1] <=> y[1] } }
          }
        when :effective_roles
          {type: :select, values: EffectiveRoles.roles}
        when :integer
          {type: :number}
        when :boolean
          {type: :boolean, values: [true, false]}
        when :datetime
          {type: :datetime}
        when :date
          {type: :date}
        else
          {type: :string}
        end.merge(filter.symbolize_keys)
      end


    end
  end
end

# This is extended as class level into Datatable

module Effective
  module EffectiveDatatable
    module Options

      def initialize_options
        @table_columns = initialize_column_options(@table_columns)
      end

      def quote_sql(name)
        collection_class.connection.quote_column_name(name) rescue name
      end

      protected

      def initialize_column_options(cols)
        sql_table = (collection.table rescue nil)

        # Here we identify all belongs_to associations and build up a Hash like:
        # {user: {foreign_key: 'user_id', klass: User}, order: {foreign_key: 'order_id', klass: Effective::Order}}
        belong_tos = (collection.klass.reflect_on_all_associations(:belongs_to) rescue []).inject({}) do |retval, bt|
          if bt.options[:polymorphic]
            retval[bt.name.to_s] = {foreign_key: bt.foreign_key, klass: bt.name, polymorphic: true}
          else
            klass = bt.klass || (bt.foreign_type.sub('_type', '').classify.constantize rescue nil)
            retval[bt.name.to_s] = {foreign_key: bt.foreign_key, klass: klass} if bt.foreign_key.present? && klass.present?
          end

          retval
        end

        # Figure out has_manys and has_many_belongs_to_many's
        has_manys = {}
        has_and_belongs_to_manys = {}

        (collection.klass.reflect_on_all_associations() rescue []).each do |reflect|
          if reflect.macro == :has_many
            klass = reflect.klass || (reflect.build_association({}).class)
            has_manys[reflect.name.to_s] = { klass: klass }
          elsif reflect.macro == :has_and_belongs_to_many
            klass = reflect.klass || (reflect.build_association({}).class)
            has_and_belongs_to_manys[reflect.name.to_s] = { klass: klass }
          end
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
          cols[name][:column] ||= (sql_table && sql_column) ? "#{quote_sql(sql_table.name)}.#{quote_sql(sql_column.name)}" : name
          cols[name][:width] ||= nil
          cols[name][:sortable] = true if cols[name][:sortable].nil?
          cols[name][:visible] = true if cols[name][:visible].nil?

          # Type
          cols[name][:type] ||= cols[name][:as]  # Use as: or type: interchangeably

          cols[name][:type] ||= (
            if belong_tos.key?(name)
              if belong_tos[name][:polymorphic]
                :belongs_to_polymorphic
              else
                :belongs_to
              end
            elsif has_manys.key?(name)
              :has_many
            elsif has_and_belongs_to_manys.key?(name)
              :has_and_belongs_to_many
            elsif cols[name][:bulk_actions_column]
              :bulk_actions_column
            elsif name.include?('_address') && (collection_class.new rescue nil).respond_to?(:effective_addresses)
              :effective_address
            elsif name == 'id' || name.include?('year') || name.include?('_id')
              :non_formatted_integer
            elsif sql_column.try(:type).present?
              sql_column.type
            else
              :string # When in doubt
            end
          )

          cols[name][:class] = "col-#{cols[name][:type]} col-#{name} #{cols[name][:class]}".strip

          # We can't really sort a HasMany or EffectiveAddress field
          if [:has_many, :effective_address].include?(cols[name][:type])
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
            cols[name][:column] = sql_table.present? ? "#{quote_sql(sql_table.name)}.#{quote_sql('roles_mask')}" : name
            cols[name][:type] = :effective_roles
          end

          if sql_table.present? && sql_column.blank? # This is a SELECT AS column, or a JOIN column
            cols[name][:sql_as_column] = true
          end

          cols[name][:filter] = initialize_table_column_filter(cols[name], belong_tos[name], has_manys[name], has_and_belongs_to_manys[name])

          if cols[name][:partial]
            cols[name][:partial_local] ||= (sql_table.try(:name) || cols[name][:partial].split('/').last(2).first.presence || 'obj').singularize.to_sym
          end
        end

        # After everything is initialized
        # Compute any col[:if] and assign an index
        count = 0
        table_columns.each do |name, col|
          if display_column?(col)
            col[:index] = count
            count += 1
          else
            # deleting rather than using `table_columns.select` above in order to maintain
            # this hash as a type of HashWithIndifferentAccess
            table_columns.delete(name)
          end
        end
      end

      def initialize_table_column_filter(column, belongs_to, has_many, has_and_belongs_to_manys)
        filter = column[:filter]
        col_type = column[:type]
        sql_column = column[:column].to_s.upcase

        return {type: :null} if filter == false

        filter = {type: filter.to_sym} if filter.kind_of?(String)
        filter = {} unless filter.kind_of?(Hash)

        # This is a fix for passing filter[:selected] == false, it needs to be 'false'
        filter[:selected] = filter[:selected].to_s unless filter[:selected].nil?

        # Allow values or collection to be used interchangeably
        if filter.key?(:collection)
          filter[:values] ||= filter[:collection]
        end

        # If you pass values, just assume it's a select
        if filter.key?(:values) && col_type != :belongs_to_polymorphic
          filter[:type] ||= :select
        end

        # Check if this is an aggregate column
        if ['SUM(', 'COUNT(', 'MAX(', 'MIN(', 'AVG('].any? { |str| sql_column.include?(str) }
          filter[:sql_operation] = :having
        end

        case col_type
        when :belongs_to
          {
            type: :select,
            values: (
              if belongs_to[:klass].respond_to?(:datatables_filter)
                Proc.new { belongs_to[:klass].datatables_filter }
              else
                Proc.new { belongs_to[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[0] <=> y[0] } }
              end
            )
          }
        when :belongs_to_polymorphic
          {type: :grouped_select, polymorphic: true, values: {}}
        when :has_many
          {
            type: :select,
            multiple: true,
            values: (
              if has_many[:klass].respond_to?(:datatables_filter)
                Proc.new { has_many[:klass].datatables_filter }
              else
                Proc.new { has_many[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[0] <=> y[0] } }
              end
            )
          }
        when :has_and_belongs_to_many
          {
            type: :select,
            multiple: true,
            values: (
              if has_and_belongs_to_manys[:klass].respond_to?(:datatables_filter)
                Proc.new { has_and_belongs_to_manys[:klass].datatables_filter }
              else
                Proc.new { has_and_belongs_to_manys[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[0] <=> y[0] } }
              end
            )
          }
        when :effective_address
          {type: :string}
        when :effective_roles
          {type: :select, values: EffectiveRoles.roles}
        when :integer
          {type: :number}
        when :boolean
          if EffectiveDatatables.boolean_format == :yes_no
            {type: :boolean, values: [['Yes', true], ['No', false]] }
          else
            {type: :boolean, values: [['true', true], ['false', false]] }
          end
        when :datetime
          {type: :datetime}
        when :date
          {type: :date}
        when :bulk_actions_column
          {type: :bulk_actions_column}
        else
          {type: :string}
        end.merge(filter.symbolize_keys)
      end

      private

      def display_column?(col)
        if col[:if].respond_to?(:call)
          (view || self).instance_exec(&col[:if])
        else
          col.fetch(:if, true)
        end
      end
    end
  end
end

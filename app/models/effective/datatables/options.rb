# This is extended as class level into Datatable

module Effective
  module Datatables
    module Options

      protected

      def table_columns_with_defaults
        unless self.class.instance_variable_get(:@table_columns_initialized)
          self.class.instance_variable_set(:@table_columns_initialized, true)
          initalize_table_columns(self.class.instance_variable_get(:@table_columns))
        end

        self.class.instance_variable_get(:@table_columns)
      end

      def initalize_table_columns(cols)
        sql_table = (collection.table rescue nil)

        # Here we identify all belongs_to associations and build up a Hash like:
        # {:user => {:foreign_key => 'user_id', :klass => User}, :order => {:foreign_key => 'order_id', :klass => Effective::Order}}
        belong_tos = (collection.ancestors.first.reflect_on_all_associations(:belongs_to) rescue []).inject(HashWithIndifferentAccess.new()) do |retval, bt|
          unless bt.options[:polymorphic]
            begin
              klass = bt.klass || bt.foreign_type.sub('_type', '').classify.constantize
            rescue => e
              klass = nil
            end

            retval[bt.name] = {:foreign_key => bt.foreign_key, :klass => klass} if bt.foreign_key.present? && klass.present?
          end

          retval
        end

        cols.each_with_index do |(name, _), index|
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
          cols[name][:sortable] = true if cols[name][:sortable] == nil
          cols[name][:type] ||= (belong_tos.key?(name) ? :belongs_to : sql_column.try(:type).presence) || :string
          cols[name][:class] = "col-#{cols[name][:type]} col-#{name} #{cols[name][:class]}".strip

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

          cols[name][:filter] = initialize_table_column_filter(cols[name][:filter], cols[name][:type], belong_tos[name])

          if cols[name][:partial]
            cols[name][:partial_local] ||= (sql_table.try(:name) || cols[name][:partial].split('/').last(2).first.presence || 'obj').singularize.to_sym
          end
        end
      end

      def initialize_table_column_filter(filter, col_type, belongs_to)
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
        when :effective_roles
          {type: :select, values: EffectiveRoles.roles}
        when :integer
          {type: :number}
        when :boolean
          {type: :boolean, values: [true, false]}
        else
          {type: :string}
        end.merge(filter.symbolize_keys)
      end


    end
  end
end

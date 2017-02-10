# This is extended as class level into Datatable

module Effective
  module EffectiveDatatable
    module Columns

      def initialize_collection_class!
        @collection_class = (the_collection.respond_to?(:klass) ? the_collection.klass : self.class)
        @active_record_collection = (the_collection.ancestors.include?(ActiveRecord::Base) rescue false)
        @array_collection = (the_collection.kind_of?(Array) && (the_collection.length == 0 || the_collection.first.kind_of?(Array)))

        unless active_record_collection? || array_collection?
          raise "Unsupported collection type. Expecting an ActiveRecord class, ActiveRecord relation, or an Array of Arrays [[1, 'something'], [2, 'something else']]"
        end
      end

      def initialize_columns!
        # And then parse all the colums
        sql_table = (the_collection.table if active_record_collection?)

        columns.each_with_index do |(name, opts), index|
          sql_column = false

          opts[:name] = name.to_s
          opts[:sql_column] = name

          opts[:as] ||= (
            if opts[:name].end_with?('_address') && defined?(EffectiveAddresses) && (collection_class.new rescue nil).respond_to?(:effective_addresses)
              :effective_address
            elsif name == :id && defined?(EffectiveObfuscation) && collection.respond_to?(:deobfuscate)
              :obfuscated_id
            elsif name == :roles && defined?(EffectiveRoles) && collection.respond_to?(:with_role)
              :effective_roles
            elsif sql_column && sql_column.type
              sql_column.type
            elsif opts[:name].end_with?('_id')
              :integer
            else
              :string # When in doubt
            end
          )

          opts[:class] = "col-#{opts[:as]} col-#{opts[:name].parameterize} #{opts[:col_class]}".strip
          opts[:label] ||= opts[:name].titleize

          opts[:index] = index  # The index of this column in the collection, regardless of hidden table_columns
        end
      end

      def initialize_filters!
        columns.each do |name, opts|
          filter = opts[:filter]

          if filter == false
            opts[:filter] = {as: :null}
            next
          end

          filter[:as] ||= :select if filter.key?(:collection)
          filter[:fuzzy] = true unless filter.key?(:fuzzy)

          type_opts = case opts[:as]
          when :belongs_to
          when :belongs_to_polymorphic
          when :has_many
          when :has_and_belongs_to_many
          when :effective_address
            {as: :string}
          when :effective_roles
            {as: :select, collection: EffectiveRoles.roles}
          when :obfuscated_id
            {as: :obfuscated_id}
          when :integer
            {as: :number}
          when :boolean
            {as: :boolean, collection: [['true', true], ['false', false]] }
          when :datetime
            {as: :datetime}
          when :date
            {as: :date}
          else
            {as: :string}
          end

          opts[:filter] = filter.reverse_merge(type_opts)
        end
      end


      # def initialize_datatable_options
      #   @table_columns = _initialize_datatable_options(@table_columns, the_collection)
      # end

      # def initialize_attributes(args)
      #   _initialize_attributes(args)
      # end

      # def initialize_scope_options
      #   @scopes = _initialize_scope_options(@scopes)
      #   _initialize_current_scope_attribute
      # end

      # def initialize_chart_options
      #   @charts = _initialize_chart_options(@charts)
      # end

      # def quote_sql(name)
      #   collection_class.connection.quote_column_name(name) rescue name
      # end

      # protected

      # def _initialize_attributes(args)
      #   args.compact.each do |arg|
      #     # ActionController::Parameters / Rails 5 hack. TODO.
      #     if arg.respond_to?(:permit)
      #       arg = (arg.respond_to?(:to_unsafe_h) ? arg.to_unsafe_h : arg.to_h)
      #     end

      #     raise "#{self.class.name}.new() can only be initialized with a Hash like arguments" unless arg.kind_of?(Hash)

      #     arg.each { |k, v| self.attributes[k] = v }
      #   end
      # end

      # # The scope DSL is
      # # scope :start_date, default_value, options: {}
      # #
      # # The value might already be assigned, but if not, we have to assign the default to attributes

      # # A scope comes to us like {:start_date => {default: Time.zone.now, filter: {as: :select, collection: ... input_html :}}}
      # # We want to make sure an input_html: { value: default } exists
      # def _initialize_scope_options(scopes)
      #   (scopes || []).each do |name, options|
      #     value = attributes.key?(name) ? attributes[name].presence : options[:default]

      #     if attributes.key?(name) == false
      #       self.attributes[name] = options[:default]
      #       value = options[:default]
      #     end

      #     if (options[:fallback] || options[:presence]) && attributes[name].blank?
      #       self.attributes[name] = options[:default]
      #       value = options[:default]
      #     end

      #     options[:filter] ||= {}
      #     options[:filter][:input_html] ||= {}
      #     options[:filter][:input_html][:value] = value
      #     options[:filter][:selected] = value
      #   end
      # end

      # def _initialize_current_scope_attribute
      #   attributes[:current_scope] ||= klass_scopes.find { |name, options| options[:klass_scope] && options[:default] }.try(:first)

      #   if attributes[:current_scope].present?
      #     attributes[:current_scope] = attributes[:current_scope].to_sym
      #     attributes[:current_scope] = nil unless klass_scopes.keys.include?(attributes[:current_scope])
      #   end

      #   if attributes[:current_scope].present?
      #     klass_scopes.each { |name, _| attributes[name] = (name == attributes[:current_scope]) }
      #   end
      # end

      # def _initialize_chart_options(charts)
      #   charts
      # end

      # def _initialize_datatable_options(cols, collection)
      #   # We set some memoized helper values
      #   @collection_class = (collection.respond_to?(:klass) ? collection.klass : self.class)
      #   @active_record_collection = (collection.ancestors.include?(ActiveRecord::Base) rescue false)
      #   @array_collection = (collection.kind_of?(Array) && (collection.length == 0 || collection.first.kind_of?(Array)))

      #   # And then parse all the colums
      #   sql_table = (collection.table rescue nil)

      #   # Here we identify all belongs_to associations and build up a Hash like:
      #   # {user: {foreign_key: 'user_id', klass: User}, order: {foreign_key: 'order_id', klass: Effective::Order}}
      #   belong_tos = (collection.klass.reflect_on_all_associations(:belongs_to) rescue []).inject({}) do |retval, bt|
      #     if bt.options[:polymorphic]
      #       retval[bt.name.to_s] = {foreign_key: bt.foreign_key, klass: bt.name, polymorphic: true}
      #     else
      #       klass = bt.klass || (bt.foreign_type.sub('_type', '').classify.constantize rescue nil)
      #       retval[bt.name.to_s] = {foreign_key: bt.foreign_key, klass: klass} if bt.foreign_key.present? && klass.present?
      #     end

      #     retval
      #   end

      #   # Figure out has_manys and has_many_belongs_to_many's
      #   has_manys = {}
      #   has_and_belongs_to_manys = {}

      #   (collection.klass.reflect_on_all_associations() rescue []).each do |reflect|
      #     if reflect.macro == :has_many
      #       klass = reflect.klass || (reflect.build_association({}).class)
      #       has_manys[reflect.name.to_s] = { klass: klass }
      #     elsif reflect.macro == :has_and_belongs_to_many
      #       klass = reflect.klass || (reflect.build_association({}).class)
      #       has_and_belongs_to_manys[reflect.name.to_s] = { klass: klass }
      #     end
      #   end

      #   table_columns = (cols || {}).each_with_index do |(name, _), index|
      #     sql_column = (collection.columns rescue []).find do |column|
      #       column.name == name.to_s || (belong_tos.key?(name) && column.name == belong_tos[name][:foreign_key])
      #     end

      #     cols[name][:array_column] ||= false
      #     cols[name][:index] = index # The index of this column in the collection, regardless of hidden table_columns
      #     cols[name][:name] ||= name
      #     cols[name][:label] ||= name.titleize
      #     cols[name][:column] ||= (sql_table && sql_column) ? "#{quote_sql(sql_table.name)}.#{quote_sql(sql_column.name)}" : name
      #     cols[name][:width] ||= nil
      #     cols[name][:sortable] = true if cols[name][:sortable].nil?
      #     cols[name][:visible] = true if cols[name][:visible].nil?

      #     # Type
      #     cols[name][:type] ||= cols[name][:as]  # Use as: or type: interchangeably

      #     cols[name][:type] ||= (
      #       if belong_tos.key?(name)
      #         if belong_tos[name][:polymorphic]
      #           :belongs_to_polymorphic
      #         else
      #           :belongs_to
      #         end
      #       elsif has_manys.key?(name)
      #         :has_many
      #       elsif has_and_belongs_to_manys.key?(name)
      #         :has_and_belongs_to_many
      #       elsif cols[name][:bulk_actions_column]
      #         :bulk_actions_column
      #       elsif name.include?('_address') && defined?(EffectiveAddresses) && (collection_class.new rescue nil).respond_to?(:effective_addresses)
      #         :effective_address
      #       elsif name == 'id' && defined?(EffectiveObfuscation) && collection.respond_to?(:deobfuscate)
      #         :obfuscated_id
      #       elsif name == 'roles' && defined?(EffectiveRoles) && collection.respond_to?(:with_role)
      #         :effective_roles
      #       elsif sql_column.try(:type).present?
      #         sql_column.type
      #       elsif name.end_with?('_id')
      #         :integer
      #       else
      #         :string # When in doubt
      #       end
      #     )

      #     cols[name][:class] = "col-#{cols[name][:type]} col-#{name.parameterize} #{cols[name][:class]}".strip

      #     # Formats
      #     if name == 'id' || name.include?('year') || name.end_with?('_id')
      #       cols[name][:format] = :non_formatted_integer
      #     end

      #     # Sortable - Disable sorting on these types
      #     if [:has_many, :effective_address, :obfuscated_id].include?(cols[name][:type])
      #       cols[name][:sortable] = false
      #     end

      #     # EffectiveRoles, if you do table_column :roles, everything just works
      #     if cols[name][:type] == :effective_roles
      #       cols[name][:column] = sql_table.present? ? "#{quote_sql(sql_table.name)}.#{quote_sql('roles_mask')}" : name
      #     end

      #     # This is a SELECT AS column, or a JOIN column or a delegated object
      #     if sql_table.present? && sql_column.blank? && !cols[name][:array_column]
      #       cols[name][:sql_as_column] = true
      #     end

      #     cols[name][:filter] = initialize_table_column_filter(cols[name], belong_tos[name], has_manys[name], has_and_belongs_to_manys[name])

      #     if cols[name][:partial]
      #       cols[name][:partial_local] ||= (sql_table.try(:name) || cols[name][:partial].split('/').last(2).first.presence || 'obj').singularize.to_sym
      #     end
      #   end

      # end

      # def initialize_table_column_filter(column, belongs_to, has_many, has_and_belongs_to_manys)
      #   filter = column[:filter]
      #   col_type = column[:type]
      #   sql_column = column[:column].to_s.upcase

      #   return {as: :null} if filter == false

      #   filter = {as: filter.to_sym} if filter.kind_of?(String)
      #   filter = {} unless filter.kind_of?(Hash)

      #   # This is a fix for passing filter[:selected] == false, it needs to be 'false'
      #   filter[:selected] = filter[:selected].to_s unless filter[:selected].nil?

      #   # Allow :values or :collection to be used interchangeably
      #   if filter.key?(:values)
      #     filter[:collection] ||= filter[:values]
      #   end

      #   # Allow :as or :type to be used interchangeably
      #   if filter.key?(:type)
      #     filter[:as] ||= filter[:type]
      #   end

      #   # If you pass a collection, just assume it's a select
      #   if filter.key?(:collection) && col_type != :belongs_to_polymorphic
      #     filter[:as] ||= :select
      #   end

      #   # Fuzzy by default throughout
      #   unless filter.key?(:fuzzy)
      #     filter[:fuzzy] = true
      #   end

      #   # Check if this is an aggregate column
      #   if ['SUM(', 'COUNT(', 'MAX(', 'MIN(', 'AVG('].any? { |str| sql_column.include?(str) }
      #     filter[:sql_operation] = :having
      #   end

      #   case col_type
      #   when :belongs_to
      #     {
      #       as: :select,
      #       collection: (
      #         if belongs_to[:klass].respond_to?(:datatables_filter)
      #           Proc.new { belongs_to[:klass].datatables_filter }
      #         elsif belongs_to[:klass].respond_to?(:sorted)
      #           Proc.new { belongs_to[:klass].sorted }
      #         else
      #           Proc.new { belongs_to[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[0] <=> y[0] } }
      #         end
      #       )
      #     }
      #   when :belongs_to_polymorphic
      #     {as: :grouped_select, polymorphic: true, collection: {}}
      #   when :has_many
      #     {
      #       as: :select,
      #       multiple: true,
      #       collection: (
      #         if has_many[:klass].respond_to?(:datatables_filter)
      #           Proc.new { has_many[:klass].datatables_filter }
      #         elsif has_many[:klass].respond_to?(:sorted)
      #           Proc.new { has_many[:klass].sorted }
      #         else
      #           Proc.new { has_many[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[0] <=> y[0] } }
      #         end
      #       )
      #     }
      #   when :has_and_belongs_to_many
      #     {
      #       as: :select,
      #       multiple: true,
      #       collection: (
      #         if has_and_belongs_to_manys[:klass].respond_to?(:datatables_filter)
      #           Proc.new { has_and_belongs_to_manys[:klass].datatables_filter }
      #         elsif has_and_belongs_to_manys[:klass].respond_to?(:sorted)
      #           Proc.new { has_and_belongs_to_manys[:klass].sorted }
      #         else
      #           Proc.new { has_and_belongs_to_manys[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[0] <=> y[0] } }
      #         end
      #       )
      #     }
      #   when :effective_address
      #     {as: :string}
      #   when :effective_roles
      #     {as: :select, collection: EffectiveRoles.roles}
      #   when :obfuscated_id
      #     {as: :obfuscated_id}
      #   when :integer
      #     {as: :number}
      #   when :boolean
      #     if EffectiveDatatables.boolean_format == :yes_no
      #       {as: :boolean, collection: [['Yes', true], ['No', false]] }
      #     else
      #       {as: :boolean, collection: [['true', true], ['false', false]] }
      #     end
      #   when :datetime
      #     {as: :datetime}
      #   when :date
      #     {as: :date}
      #   when :bulk_actions_column
      #     {as: :bulk_actions_column}
      #   else
      #     {as: :string}
      #   end.merge(filter.symbolize_keys)
      # end

    end
  end
end

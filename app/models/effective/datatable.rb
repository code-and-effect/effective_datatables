module Effective
  class Datatable
    attr_accessor :total_records, :display_records, :view, :attributes

    delegate :render, :link_to, :mail_to, :to => :@view

    class << self
      def all
        EffectiveDatatables.datatables.map { |klass| klass.new() }
      end

      def find(obj, attributes = nil)
        obj = obj.respond_to?(:to_param) ? obj.to_param : obj
        EffectiveDatatables.datatables.find { |klass| klass.name.underscore.parameterize == obj }.try(:new, attributes.presence || {})
      end

      def table_column(name, options = {}, proc = nil, &block)
        if block_given?
          raise "You cannot use :partial => '' with the block syntax" if options[:partial]
          raise "You cannot use :proc => ... with the block syntax" if options[:proc]
          options[:block] = block
        end
        raise "You cannot use both :partial => '' and proc => ..." if options[:partial] && options[:proc]

        send(:attr_accessor, name)
        (@table_columns ||= HashWithIndifferentAccess.new())[name] = options
      end

      def table_columns(*names)
        names.each { |name| table_column(name) }
      end

      def array_column(name, options = {}, proc = nil, &block)
        table_column(name, options.merge({:array_column => true}), proc, &block)
      end

      def array_columns(*names)
        names.each { |name| array_column(name) }
      end

      def default_order(name, direction = :asc)
        @default_order = {name => direction}
      end

      def default_entries(entries)
        @default_entries = entries
      end

      def model_name # Searching & Filters
        @model_name ||= ActiveModel::Name.new(self)
      end
    end


    def initialize(*args)
      unless active_record_collection? || (collection.kind_of?(Array) && collection.first.kind_of?(Array))
        raise "Unsupported collection type. Should be ActiveRecord class, ActiveRecord relation, or an Array of Arrays [[1, 'something'], [2, 'something else']]"
      end

      if args.present?
        raise 'Effective::Datatable.new() can only be called with a Hash like arguments' unless args.first.kind_of?(Hash)
        args.first.each { |k, v| self.attributes[k] = v }
      end

      # Any pre-selected search terms should be assigned now
      search_terms.each { |column, term| self.send("#{column}=", term) }
    end

    # Any attributes set on initialize will be echoed back and available to the class
    def attributes
      @attributes ||= HashWithIndifferentAccess.new()
    end

    def to_key; []; end # Searching & Filters

    # Instance method.  In Rails 4.2 this needs to be defined on the instance, before it was on the class
    def model_name # Searching & Filters
      @model_name ||= ActiveModel::Name.new(self.class)
    end

    def to_param
      self.class.name.underscore.parameterize
    end

    def collection
      raise "You must define a collection. Something like an ActiveRecord User.all or an Array of Arrays [[1, 'something'], [2, 'something else']]"
    end

    def collection_class
      collection.respond_to?(:klass) ? collection.klass : self.class
    end

    def finalize(collection) # Override me if you like
      collection
    end

    # Select only col[:if] == true columns, and then set the col[:index] accordingly
    def table_columns
      @table_columns ||= table_columns_with_defaults().select do |_, col|
        col[:if] == nil || (col[:if].respond_to?(:call) ? (view || self).instance_exec(&col[:if]) : col[:if])
      end.each_with_index { |(_, col), index| col[:index] = index }
    end

    # This is for the ColReorder plugin
    # It sends us a list of columns that are different than our table_columns order
    # So this method just returns an array of column names, as per ColReorder
    def display_table_columns
      if params[:columns].present?
        HashWithIndifferentAccess.new().tap do |display_columns|
          params[:columns].each do |_, values|
            display_columns[values[:name]] = table_columns[values[:name]]
          end
        end
      end
    end

    def to_json
      raise 'Effective::Datatable to_json called with a nil view.  Please call render_datatable(@datatable) or @datatable.view = view before this method' unless view.present?

      @json ||= {
        :draw => (params[:draw] || 0),
        :data => (table_data || []),
        :recordsTotal => (total_records || 0),
        :recordsFiltered => (display_records || 0)
      }
    end

    def present?
      total_records.to_i > 0
    end

    def empty?
      total_records.to_i == 0
    end

    def order_name
      @order_name ||= begin
        if params[:order] && params[:columns]
          order_column_index = (params[:order].first[1][:column] rescue '0')
          (params[:columns][order_column_index] || {})[:name]
        elsif default_order.present?
          default_order.keys.first
        end || table_columns.keys.first
      end
    end

    def order_direction
      @order_direction ||= if params[:order].present?
        params[:order].first[1][:dir] == 'desc' ? 'DESC' : 'ASC'
      elsif default_order.present?
        default_order.values.first.to_s.downcase == 'desc' ? 'DESC' : 'ASC'
      else
        'ASC'
      end
    end

    def default_order
      self.class.instance_variable_get(:@default_order)
    end

    def default_entries
      @default_entries ||= begin
        entries = (self.class.instance_variable_get(:@default_entries).presence || EffectiveDatatables.default_entries)
        entries = -1 if entries.to_s.downcase == 'all'
        [10, 25, 50, 100, 250, 1000, -1].include?(entries) ? entries : 25
      end
    end

    def search_terms
      @search_terms ||= HashWithIndifferentAccess.new().tap do |terms|
        if params[:columns].present? # This is an AJAX request from the DataTable
          (params[:columns] || {}).each do |_, column|
            next if table_columns[column[:name]].blank? || (column[:search] || {})[:value].blank?

            terms[column[:name]] = column[:search][:value]
          end
        else # This is the initial render, and we have to apply default search terms only
          table_columns.each do |name, values|
            terms[name] = values[:filter][:selected] if values[:filter][:selected].present?
          end
        end
      end
    end

    # This is here so classes that inherit from Datatables can can override the specific where clauses on a search column
    def search_column(collection, table_column, search_term)
      if table_column[:array_column]
        array_tool.search_column_with_defaults(collection, table_column, search_term)
      else
        table_tool.search_column_with_defaults(collection, table_column, search_term)
      end
    end

    def per_page
      length = (params[:length].presence || default_entries).to_i

      if length == -1
        9999999
      elsif length > 0
        length
      else
        25
      end
    end

    def per_page=(length)
      case length
      when Integer
        params[:length] = length
      when :all
        params[:length] = -1
      end
    end

    def page
      params[:start].to_i / per_page + 1
    end

    def total_records
      @total_records ||= (
        if active_record_collection?
          (collection_class.connection.execute("SELECT COUNT(*) FROM (#{collection.to_sql}) AS datatables_total_count").first['count'] rescue 1).to_i
        else
          collection.size
        end
      )
    end

    def view=(view_context)
      @view = view_context
      @view.formats = [:html]

      # 'Just work' with attributes
      @view.class.send(:attr_accessor, :attributes)
      @view.attributes = self.attributes

      # Delegate any methods defined on the datatable directly to our view
      @view.class.send(:attr_accessor, :effective_datatable)
      @view.effective_datatable = self

      (self.class.instance_methods(false) - [:collection, :search_column]).each do |view_method|
        @view.class_eval { delegate view_method, :to => :@effective_datatable }
      end

      # Clear the search_terms memoization
      @search_terms = nil
      @order_name = nil
      @order_direction = nil
    end


    protected

    # So the idea here is that we want to do as much as possible on the database in ActiveRecord
    # And then run any array_columns through in post-processed results
    def table_data
      col = collection

      if active_record_collection?
        col = table_tool.order(col)
        col = table_tool.search(col)

        if table_tool.search_terms.present? && array_tool.search_terms.blank?
          self.display_records = (collection_class.connection.execute("SELECT COUNT(*) FROM (#{col.to_sql}) AS datatables_filtered_count").first['count'] rescue 1).to_i
        end
      end

      if array_tool.search_terms.present?
        col = self.arrayize(col)
        col = array_tool.search(col)
        self.display_records = col.size
      end

      if array_tool.order_column.present?
        col = self.arrayize(col)
        col = array_tool.order(col)
      end

      self.display_records ||= total_records

      if col.kind_of?(Array)
        col = array_tool.paginate(col)
      else
        col = table_tool.paginate(col)
        col = self.arrayize(col)
      end

      col = self.finalize(col)
    end

    def arrayize(collection)
      return collection if @arrayized  # Prevent the collection from being arrayized more than once
      @arrayized = true

      # We want to use the render :collection for each column that renders partials
      rendered = {}
      table_columns.each do |name, opts|
        if opts[:partial]
          rendered[name] = (render(
            :partial => opts[:partial],
            :as => opts[:partial_local],
            :collection => collection,
            :formats => :html,
            :locals => {:datatable => self},
            :spacer_template => '/effective/datatables/spacer_template',
          ) || '').split('EFFECTIVEDATATABLESSPACER')
        end
      end

      collection.each_with_index.map do |obj, index|
        (display_table_columns || table_columns).map do |name, opts|
          value = if opts[:partial]
            rendered[name][index]
          elsif opts[:block]
            view.instance_exec(obj, collection, self, &opts[:block])
          elsif opts[:proc]
            view.instance_exec(obj, collection, self, &opts[:proc])
          elsif opts[:type] == :belongs_to
            val = (obj.send(name) rescue nil).to_s
          elsif opts[:type] == :obfuscated_id
            (obj.send(:to_param) rescue nil).to_s
          else
            val = (obj.send(name) rescue nil)
            val = (obj[opts[:array_index]] rescue nil) if val == nil
            val
          end

          # Last minute formatting of dates
          case value
          when Date
            value.strftime(EffectiveDatatables.date_format)
          when Time
            value.strftime(EffectiveDatatables.datetime_format)
          when DateTime
            value.strftime(EffectiveDatatables.datetime_format)
          else
            value
          end
        end
      end
    end

    private

    def params
      view.try(:params) || HashWithIndifferentAccess.new()
    end

    def table_tool
      @table_tool ||= ActiveRecordDatatableTool.new(self, table_columns.select { |_, col| col[:array_column] == false })
    end

    def array_tool
      @array_tool ||= ArrayDatatableTool.new(self, table_columns.select { |_, col| col[:array_column] == true })
    end

    def active_record_collection?
      if @active_record_collection.nil?
        @active_record_collection = (collection.ancestors.include?(ActiveRecord::Base) rescue false)
      else
        @active_record_collection
      end
    end

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
          cols[name][:if] ||= Proc.new { attributes[belong_tos[name][:foreign_key]].blank? } # :if => Proc.new { attributes[:user_id].blank? }
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
        cols[name][:type] ||= (belong_tos.key?(name) ? :belongs_to : (sql_column.try(:type).presence || :string))
        cols[name][:class] = "col-#{cols[name][:type]} col-#{name} #{cols[name][:class]}".strip

        if name == 'id' && collection.respond_to?(:deobfuscate)
          cols[name][:sortable] = false
          cols[name][:type] = :obfuscated_id
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
      return {:type => :null} if filter == false

      if filter.kind_of?(Symbol)
        filter = HashWithIndifferentAccess.new(:type => filter)
      elsif filter.kind_of?(String)
        filter = HashWithIndifferentAccess.new(:type => filter.to_sym)
      elsif filter.kind_of?(Hash) == false
        filter = HashWithIndifferentAccess.new()
      end

      # This is a fix for passing filter[:selected] == false, it needs to be 'false'
      filter[:selected] = filter[:selected].to_s unless filter[:selected].nil?

      filter = case col_type
      when :belongs_to
        HashWithIndifferentAccess.new(
          :type => :select,
          :values => Proc.new { belongs_to[:klass].all.map { |obj| [obj.to_s, obj.id] }.sort { |x, y| x[1] <=> y[1] } }
        ).merge(filter)
      when :integer
        HashWithIndifferentAccess.new(:type => :number).merge(filter)
      when :boolean
        HashWithIndifferentAccess.new(:type => :boolean, :values => [true, false]).merge(filter)
      else
        HashWithIndifferentAccess.new(:type => :string).merge(filter)
      end

      if filter[:type] == :boolean
        filter = HashWithIndifferentAccess.new(:values => [true, false]).merge(filter)
      end

      filter
    end

  end
end

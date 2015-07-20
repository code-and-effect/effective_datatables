module Effective
  class Datatable
    attr_accessor :total_records, :display_records, :view, :attributes

    delegate :render, :link_to, :mail_to, :to => :@view

    extend Effective::Datatables::Dsl
    include Effective::Datatables::Ajax


    def initialize(*args)
      if args.present?
        raise 'Effective::Datatable.new() can only be called with a Hash like arguments' unless args.first.kind_of?(Hash)
        args.first.each { |k, v| self.attributes[k] = v }
      end

      if self.respond_to?(:dynamic_columns)
        dynamic_columns()
        initalize_table_columns(self.class.instance_variable_get(:@table_columns))
      end

      unless active_record_collection? || (collection.kind_of?(Array) && collection.first.kind_of?(Array))
        raise "Unsupported collection type. Should be ActiveRecord class, ActiveRecord relation, or an Array of Arrays [[1, 'something'], [2, 'something else']]"
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

    def total_records
      @total_records ||= (
        if active_record_collection? && collection_class.connection.respond_to?(:unprepared_statement)
          # https://github.com/rails/rails/issues/15331
          collection_sql = collection_class.connection.unprepared_statement { collection.to_sql }
          (collection_class.connection.execute("SELECT COUNT(*) FROM (#{collection_sql}) AS datatables_total_count").first['count'] rescue 1).to_i
        elsif active_record_collection?
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

      (self.class.instance_methods(false) - [:collection, :search_column, :dynamic_columns]).each do |view_method|
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
          if collection_class.connection.respond_to?(:unprepared_statement)
            # https://github.com/rails/rails/issues/15331
            col_sql = collection_class.connection.unprepared_statement { col.to_sql }
            self.display_records = (collection_class.connection.execute("SELECT COUNT(*) FROM (#{col_sql}) AS datatables_filtered_count").first['count'] rescue 1).to_i
          else
            self.display_records = (collection_class.connection.execute("SELECT COUNT(*) FROM (#{col.to_sql}) AS datatables_filtered_count").first['count'] rescue 1).to_i
          end
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
          locals = {
            datatable: self,
            table_column: table_columns[name],
            controller_namespace: view.controller_path.split('/')[0...-1].map { |path| path.downcase.to_sym if path.present? }.compact,
            show_action: (opts[:partial_locals] || {})[:show_action],
            edit_action: (opts[:partial_locals] || {})[:edit_action],
            destroy_action: (opts[:partial_locals] || {})[:destroy_action]
          }
          locals.merge!(opts[:partial_locals]) if opts[:partial_locals]

          rendered[name] = (render(
            :partial => opts[:partial],
            :as => opts[:partial_local],
            :collection => collection,
            :formats => :html,
            :locals => locals,
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
          elsif opts[:type] == :effective_roles
            (obj.send(:roles) rescue []).join(', ')
          else
            val = (obj.send(name) rescue nil)
            val = (obj[opts[:array_index]] rescue nil) if val == nil
            val
          end

          # Last minute formatting of dates
          case value
          when Date
            value.strftime(EffectiveDatatables.date_format)
          when Time, DateTime
            value.strftime(EffectiveDatatables.datetime_format)
          else
            value.to_s
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

    # This is a dynamic_table column called from within dynamic_columns do .. end
    def table_column(name, options = {}, proc = nil, &block)
      if block_given?
        self.class.table_column(name, options.merge(dynamic: true), proc) { yield }
      else
        self.class.table_column(name, options.merge(dynamic: true), proc)
      end
    end

    def array_column(name, options = {}, proc = nil, &block)
      if block_given?
        self.class.array_column(name, options.merge(dynamic: true), proc) { yield }
      else
        self.class.array_column(name, options.merge(dynamic: true), proc)
      end
    end


  end
end

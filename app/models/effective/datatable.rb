module Effective
  class Datatable
    attr_accessor :display_records, :view, :attributes

    # These two options control the render behaviour of a datatable
    attr_accessor :table_html_class, :simple

    delegate :render, :controller, :link_to, :mail_to, :number_to_currency, :number_to_percentage, :to => :@view

    extend Effective::EffectiveDatatable::Dsl
    include Effective::EffectiveDatatable::Dsl::BulkActions
    include Effective::EffectiveDatatable::Dsl::Charts
    include Effective::EffectiveDatatable::Dsl::Datatable
    include Effective::EffectiveDatatable::Dsl::Scopes

    include Effective::EffectiveDatatable::Ajax
    include Effective::EffectiveDatatable::Charts
    include Effective::EffectiveDatatable::Helpers
    include Effective::EffectiveDatatable::Hooks
    include Effective::EffectiveDatatable::Options
    include Effective::EffectiveDatatable::Rendering

    def initialize(*args)
      if args.present? && args.first != nil
        raise "#{self.class.name}.new() can only be initialized with a Hash like arguments" unless args.first.kind_of?(Hash)
        args.first.each { |k, v| self.attributes[k] = v }
      end

      if respond_to?(:initialize_scopes)  # There was at least one scope defined in the scopes do .. end block
        initialize_scopes
        initialize_scope_options
      end

      if respond_to?(:initialize_datatable)
        initialize_datatable          # This creates @table_columns based on the DSL datatable do .. end block
        initialize_datatable_options  # This normalizes all the options
      end

      if respond_to?(:initialize_charts)
        initialize_charts
        initialize_chart_options
      end

      unless active_record_collection? || array_collection?
        raise "Unsupported collection type. Should be ActiveRecord class, ActiveRecord relation, or an Array of Arrays [[1, 'something'], [2, 'something else']]"
      end

      if @default_order.present? && !table_columns.key?((@default_order.keys.first rescue nil))
        raise "default_order :#{(@default_order.keys.first rescue 'nil')} must exist as a table_column or array_column"
      end
    end

    def table_columns
      @table_columns
    end

    def scopes
      @scopes
    end

    def charts
      @charts
    end

    def aggregates
      @aggregates
    end

    # Any attributes set on initialize will be echoed back and available to the class
    def attributes
      @attributes ||= HashWithIndifferentAccess.new
    end

    def to_key; []; end # Searching & Filters

    # Instance method.  In Rails 4.2 this needs to be defined on the instance, before it was on the class
    def model_name # Searching & Filters
      @model_name ||= ActiveModel::Name.new(self.class)
    end

    def self.model_name # Searching & Filters
      @model_name ||= ActiveModel::Name.new(self)
    end

    def to_param
      @to_param ||= self.class.name.underscore.sub('effective/datatables/', '')
    end

    def collection
      raise "You must define a collection. Something like an ActiveRecord User.all or an Array of Arrays [[1, 'something'], [2, 'something else']]"
    end

    def collection_class
      @collection_class ||= (collection.respond_to?(:klass) ? collection.klass : self.class)
    end

    def to_json
      raise 'Effective::Datatable to_json called with a nil view.  Please call render_datatable(@datatable) or @datatable.view = view before this method' unless view.present?

      @json ||= begin
        data = table_data

        {
          :draw => (params[:draw] || 0),
          :data => (data || []),
          :recordsTotal => (total_records || 0),
          :recordsFiltered => (display_records || 0),
          :aggregates => (aggregate_data(data) || []),
          :charts => (charts_data || {})
        }
      end
    end

    def present?
      total_records.to_i > 0
    end

    def empty?
      total_records.to_i == 0
    end

    def total_records
      @total_records ||= (
        if active_record_collection?
          if collection_class.connection.respond_to?(:unprepared_statement)
            collection_sql = collection_class.connection.unprepared_statement { collection.to_sql }
            (collection_class.connection.execute("SELECT COUNT(*) FROM (#{collection_sql}) AS datatables_total_count").first.values.first rescue 1).to_i
          else
            (collection_class.connection.execute("SELECT COUNT(*) FROM (#{collection.to_sql}) AS datatables_total_count").first.values.first rescue 1).to_i
          end
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

      (self.class.instance_methods(false) - [:collection, :search_column, :order_column]).each do |view_method|
        @view.class_eval { delegate view_method, to: :@effective_datatable }
      end

      Effective::EffectiveDatatable::Dsl::BulkActions.instance_methods(false).each do |helper_method|
        @view.class_eval { delegate helper_method, to: :@effective_datatable }
      end

      Effective::EffectiveDatatable::Helpers.instance_methods(false).each do |helper_method|
        @view.class_eval { delegate helper_method, to: :@effective_datatable }
      end

      # Clear the search_terms memoization
      @search_terms = nil
      @order_name = nil
      @order_direction = nil
    end

    def view_context
      view
    end

    def table_html_class
      @table_html_class.presence || 'table table-bordered table-striped'
    end

    # When simple only a table will be rendered with
    # no sorting, no filtering, no export buttons, no pagination, no per page, no colReorder
    # default sorting only, default visibility only, all records returned, and responsive enabled
    def simple?
      @simple == true
    end

    protected

    def params
      view.try(:params) || HashWithIndifferentAccess.new()
    end

    def table_tool
      @table_tool ||= ActiveRecordDatatableTool.new(self, table_columns.reject { |_, col| col[:array_column] })
    end

    def array_tool
      @array_tool ||= ArrayDatatableTool.new(self, table_columns.select { |_, col| col[:array_column] })
    end

    def active_record_collection?
      collection.ancestors.include?(ActiveRecord::Base) rescue false
    end

    def array_collection?
      collection.kind_of?(Array) && collection.first.kind_of?(Array)
    end

  end
end

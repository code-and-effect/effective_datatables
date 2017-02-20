module Effective
  class Datatable
    # Anything that we initialize our table with. That's it. Can't be changed by state.
    attr_reader :attributes
    attr_reader :resource
    attr_reader :state

    # Hashes of DSL options
    attr_reader :bulk_actions
    attr_reader :columns
    attr_reader :filters
    attr_reader :scopes

    # The collection itself. Only evaluated once.
    attr_accessor :collection

    # The view, and the ajax/cookie/default state
    attr_reader :cookie
    attr_reader :view

    extend Effective::EffectiveDatatable::Dsl

    include Effective::EffectiveDatatable::Attributes
    include Effective::EffectiveDatatable::Cookie
    include Effective::EffectiveDatatable::Hooks
    include Effective::EffectiveDatatable::Collection
    include Effective::EffectiveDatatable::Filters
    include Effective::EffectiveDatatable::Params
    include Effective::EffectiveDatatable::Render
    include Effective::EffectiveDatatable::Resource
    include Effective::EffectiveDatatable::State

    def initialize(args = {})
      @attributes = initial_attributes(args)

      @bulk_actions = []
      @columns = {}
      @filters = {}
      @scopes = {}

      @state = initial_state
    end

    # Once the view is assigned, we initialize everything
    def view=(view_context)
      @view = view_context

      # Any datatable specific functions we want available in the DSL blocks need to be defined on the view
      view.class_eval do
        attr_accessor :datatable
        include Effective::EffectiveDatatable::Dsl::BulkActions
        include Effective::EffectiveDatatable::Dsl::Datatable
        include Effective::EffectiveDatatable::Dsl::Filters
        include Effective::EffectiveDatatable::Dsl::View
      end

      view.datatable = self
      load_cookie!
      load_attributes!

      # We need early access to filter and scope, to define defaults from the model first
      # This means filters do knows about attributes but not about columns.
      initialize_filters if respond_to?(:initialize_filters)
      load_filters!
      load_state!

      # Now we initialize all the columns. columns knows about attributes and filters and scope
      initialize_datatable if respond_to?(:initialize_datatable)
      load_columns!

      # Execute any additional DSL methods
      initialize_bulk_actions if respond_to?(:initialize_bulk_actions)
      initialize_charts if respond_to?(:initialize_charts)

      # Load the collection. This is the first time def collection is called on the Datatable itself
      initialize_collection if respond_to?(:initialize_collection)
      load_collection!

      # Figure out the class, and if it's activerecord, do all the resource discovery on it
      load_resource!

      save_cookie!
    end

    def present?
      total_records > 0
    end

    def blank?
      total_records == 0
    end

    def display_records
      @display_records || 0
    end

    def total_records
      @total_records ||= (active_record_collection? ? table_tool.size(collection) : array_tool.size(collection))
    end

    def to_json
      @json ||= (
        data = table_data

        {
          draw: (params[:draw] || 0),
          data: (data || []),
          recordsTotal: (total_records || 0),
          recordsFiltered: (display_records || 0),
          aggregates: [], #(aggregate_data(data) || []),
          charts: {} #(charts_data || {})
        }
      )
    end

    # When simple only a table will be rendered with
    # no sorting, no filtering, no export buttons, no pagination, no per page, no colReorder
    # default sorting only, default visibility only, all records returned, and responsive enabled
    def simple?
      attributes[:simple]
    end

    def table_html_class
      attributes[:class] || 'table table-bordered table-striped'
    end

    def to_param
      @to_param ||= self.class.name.underscore.parameterize
    end

    private

    def table_tool
      @table_tool ||= ActiveRecordDatatableTool.new(self)
    end

    def array_tool
      @array_tool ||= ArrayDatatableTool.new(self)
    end

  end
end

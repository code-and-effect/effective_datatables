module Effective
  class Datatable
    # Anything that we initialize our table with. That's it.
    attr_reader :attributes

    # Hashes of DSL options
    attr_reader :bulk_actions
    attr_reader :columns
    attr_reader :filterdefs
    attr_reader :scopes

    # The view, and the ajax/cookie/default state
    attr_reader :view
    attr_reader :state

    extend Effective::EffectiveDatatable::Dsl

    include Effective::EffectiveDatatable::Attributes
    include Effective::EffectiveDatatable::Cookie
    include Effective::EffectiveDatatable::Hooks
    include Effective::EffectiveDatatable::Columns
    include Effective::EffectiveDatatable::Filters
    include Effective::EffectiveDatatable::Rendering
    include Effective::EffectiveDatatable::State

    def initialize(args = {})
      @attributes = initial_attributes(args)
      @bulk_actions = []
      @columns = {}
      @filterdefs = {}
      @scopes = {}
    end

    # Once the view is assigned, we initialize everything
    def view=(view_context)
      @view = view_context

      # Any datatable specific functions we want available in the DSL blocks need to be defined on the view
      view.class_eval do
        attr_accessor :attributes, :datatable, :state
        include Effective::EffectiveDatatable::Dsl::BulkActions
        include Effective::EffectiveDatatable::Dsl::Datatable
        include Effective::EffectiveDatatable::Dsl::Filters
      end

      view.datatable = self
      initialize_cookie!
      initialize_attributes!

      # We need early access to filter and scope, to define defaults from the model first
      # This means filters do knows about attributes but not about columns.
      initialize_filters if respond_to?(:initialize_filters)
      initialize_state!

      # Now we initialize all the columns
      # columns knows about attributes and filters and scope
      initialize_datatable if respond_to?(:initialize_datatable)
      load_columns_state!

      # Execute any additional DSL methods
      initialize_bulk_actions if respond_to?(:initialize_bulk_actions)
      initialize_charts if respond_to?(:initialize_charts)

      binding.pry

      # Load the collection. This is the first time def collection is called on the Datatable itself
      initialize_collection!
      initialize_collection_class!

      # Figure out the class, and if it's activerecord, do all the resource discovery on it
      initialize_columns!
      initialize_column_filters!

      save_cookie!
    end

    def initialize_collection!
      @memoized_collection ||= collection
    end

    def collection
      raise "You must define a collection. Something like an ActiveRecord User.all or an Array of Arrays [[1, 'something'], [2, 'something else']]"
    end

    def collection_class
      @collection_class  # Will be either User/Post/etc or Array
    end

    def present?
      total_records > 0
    end

    def empty?
      total_records == 0
    end

    def display_records
      @display_records
    end

    def total_records
      @total_records ||= (active_record_collection? ? table_tool.size(the_collection) : array_tool.size(the_collection))
    end

    def to_json
      @json ||= (
        data = table_data

        {
          draw: (view.params[:draw] || 0),
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

    protected

    def the_collection
      @memoized_collection ||= collection
    end

    def active_record_collection?
      @active_record_collection == true
    end

    def array_collection?
      @array_collection == true
    end

    def datatables_ajax_request?
      view && view.params[:draw] && view.params[:columns] && view.params[:id] == to_param
    end

    def table_tool
      @table_tool ||= ActiveRecordDatatableTool.new(self, columns.reject { |_, col| col[:array_column] })
    end

    def array_tool
      @array_tool ||= ArrayDatatableTool.new(self, columns.select { |_, col| col[:array_column] })
    end

  end
end

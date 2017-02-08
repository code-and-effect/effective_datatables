module Effective
  class Datatable
    attr_reader :columns  # All defined columns
    attr_reader :attributes     # Anything that we initialize our table with. That's it.
    attr_reader :state          # Any selected values
    attr_reader :view

    extend Effective::EffectiveDatatable::Dsl

    include Effective::EffectiveDatatable::Ajax
    include Effective::EffectiveDatatable::Hooks
    include Effective::EffectiveDatatable::Options
    include Effective::EffectiveDatatable::Rendering
    include Effective::EffectiveDatatable::State

    def initialize(args = {})
      @attributes = initialize_attributes(args)
      @state = initialize_state
      @columns = {}
    end

    # Once the view is assigned, we initialize everything
    def view=(view_context)
      @view = view_context

      # Any datatable specific functions we want available in the DSL blocks need to be defined on the view
      view.class_eval do
        attr_accessor :attributes, :state, :datatable
        include Effective::EffectiveDatatable::Dsl::Datatable
      end

      view.attributes = attributes
      view.datatable = self
      view.state = state

      # Execute the the DSL methods
      initialize_datatable if respond_to?(:initialize_datatable)
      initialize_charts if respond_to?(:initialize_charts)
      initialize_scopes if respond_to?(:initialize_scopes)

      # Normalize and validate all the options
      initialize_collection_class!  # This is the first time the_collection() is called
      initialize_columns!
      initialize_filters!
      load_state!
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
      self.class.name.underscore
    end

    def scopes
      nil
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

    def table_tool
      @table_tool ||= ActiveRecordDatatableTool.new(self, columns.reject { |_, col| col[:array_column] })
    end

    def array_tool
      @array_tool ||= ArrayDatatableTool.new(self, columns.select { |_, col| col[:array_column] })
    end

  end
end

module Effective
  class Datatable
    attr_reader :attributes # Anything that we initialize our table with. That's it. Can't be changed by state.
    attr_reader :resource
    attr_reader :state

    # Hashes of DSL options
    attr_reader :_aggregates
    attr_reader :_bulk_actions
    attr_reader :_charts
    attr_reader :_columns
    attr_reader :_filters
    attr_reader :_form
    attr_reader :_scopes

    # The collection itself. Only evaluated once.
    attr_accessor :_collection

    # The view
    attr_reader :view

    extend Effective::EffectiveDatatable::Dsl

    include Effective::EffectiveDatatable::Attributes
    include Effective::EffectiveDatatable::Collection
    include Effective::EffectiveDatatable::Compute
    include Effective::EffectiveDatatable::Cookie
    include Effective::EffectiveDatatable::Format
    include Effective::EffectiveDatatable::Hooks
    include Effective::EffectiveDatatable::Params
    include Effective::EffectiveDatatable::Resource
    include Effective::EffectiveDatatable::State

    def initialize(view = nil, attributes = {})
      (attributes = view; view = nil) if view.kind_of?(Hash)

      @attributes = initial_attributes(attributes)
      @state = initial_state

      @_aggregates = {}
      @_bulk_actions = []
      @_charts = {}
      @_columns = {}
      @_filters = {}
      @_form = {}
      @_scopes = {}

      raise 'collection is defined as a method. Please use the collection do ... end syntax.' unless collection.nil?
      self.view = view if view
    end

    # Once the view is assigned, we initialize everything
    def view=(view)
      @view = (view.respond_to?(:view_context) ? view.view_context : view)
      raise 'expected view to respond to params' unless @view.respond_to?(:params)

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

      # If attributes match a belongs_to column, scope the collection and remove the column
      apply_belongs_to_attributes!

      save_cookie!
    end

    def present?(view = nil)
      unless (@view || view)
        raise 'unable to call present? without an assigned view. In your view, either call render_datatable(@datatable) first, or use @datatable.present?(self)'
      end

      self.view ||= view

      to_json[:recordsTotal] > 0
    end

    def blank?(view = nil)
      unless (@view || view)
        raise 'unable to call blank? without an assigned view. In your view, either call render_datatable(@datatable) first, or use @datatable.blank?(self)'
      end

      self.view ||= view

      to_json[:recordsTotal] == 0
    end

    def to_json
      @json ||= (
        {
          data: (compute || []),
          draw: (params[:draw] || 0),
          recordsTotal: (@total_records || 0),
          recordsFiltered: (@display_records || 0),
          aggregates: (@aggregates_data || []),
          charts: (@charts_data || {})
        }
      )
    end

    # When simple only a table will be rendered with
    # no sorting, no filtering, no export buttons, no pagination, no per page, no colReorder
    # default sorting only, default visibility only, all records returned, and responsive enabled
    def simple?
      attributes[:simple] == true
    end

    # Inline crud
    def inline?
      attributes[:inline] == true
    end

    # Whether the filters must be rendered as a <form> or we can keep the normal <div> behaviour
    def _filters_form_required?
      _form[:verb].present?
    end

    def table_html_class
      attributes[:class] || EffectiveDatatables.html_class
    end

    def to_param
      @to_param ||= "#{self.class.name.underscore.parameterize}-#{cookie_param}"
    end

    def columns
      @_columns
    end

    def collection
      @_collection
    end

    def dsl_tool
      @dsl_tool ||= DatatableDslTool.new(self)
    end

    private

    def column_tool
      @column_tool ||= DatatableColumnTool.new(self)
    end

    def value_tool
      @value_tool ||= DatatableValueTool.new(self)
    end

  end
end

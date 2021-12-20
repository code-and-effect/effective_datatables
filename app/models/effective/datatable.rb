# frozen_string_literal: true

module Effective
  class Datatable
    attr_reader :attributes # Anything that we initialize our table with. That's it. Can't be changed by state.
    attr_reader :state
    attr_accessor :effective_resource

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
    attr_accessor :_collection_apply_belongs_to
    attr_accessor :_collection_apply_scope

    # The view
    attr_reader :view

    # Set by DSL so we can track where this datatable is coming from
    attr_accessor :source_location

    extend Effective::EffectiveDatatable::Dsl

    include Effective::EffectiveDatatable::Attributes
    include Effective::EffectiveDatatable::Collection
    include Effective::EffectiveDatatable::Compute
    include Effective::EffectiveDatatable::Cookie
    include Effective::EffectiveDatatable::Csv
    include Effective::EffectiveDatatable::Format
    include Effective::EffectiveDatatable::Hooks
    include Effective::EffectiveDatatable::Params
    include Effective::EffectiveDatatable::Resource
    include Effective::EffectiveDatatable::State

    def initialize(view = nil, attributes = nil)
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

      raise 'expected a hash of arguments' unless @attributes.kind_of?(Hash)
      raise 'collection is defined as a method. Please use the collection do ... end syntax.' unless collection.nil?

      self.view = view if view
    end

    def rendered(params = {})
      raise('expected a hash of params') unless params.kind_of?(Hash)

      view = ApplicationController.renderer.controller.helpers

      view.class_eval do
        attr_accessor :rendered_params

        def current_user
          rendered_params[:current_user]
        end
      end

      if params[:current_user_id]
        params[:current_user] = User.find(params[:current_user_id])
      end

      view.rendered_params = params

      self.view = view
      self
    end

    # Once the view is assigned, we initialize everything
    def view=(view)
      @view = (view.respond_to?(:view_context) ? view.view_context : view)

      unless @view.respond_to?(:params) || @view.respond_to?(:rendered_params)
        raise 'expected view to respond to params'
      end

      assert_attributes!
      load_attributes!

      # We need early access to filter and scope, to define defaults from the model first
      # This means filters do know about attributes but not about columns.
      initialize_filters if respond_to?(:initialize_filters)
      load_filters!
      load_state!

      # Bulk actions called first so it can add the bulk_actions_col first
      initialize_bulk_actions if respond_to?(:initialize_bulk_actions)

      # Now we initialize all the columns. columns knows about attributes and filters and scope
      initialize_datatable if respond_to?(:initialize_datatable)
      load_columns!

      # Execute any additional DSL methods
      initialize_charts if respond_to?(:initialize_charts)

      # Load the collection. This is the first time def collection is called on the Datatable itself
      initialize_collection if respond_to?(:initialize_collection)
      load_collection!

      # Figure out the class, and if it's activerecord, do all the resource discovery on it
      load_resource!

      # Check everything is okay
      validate_datatable!

      # Save for next time
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

    def to_csv
      csv_file()
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

    # Inline crud
    def inline?
      attributes[:inline] == true
    end

    # Reordering
    def reorder?
      columns.key?(:_reorder)
    end

    def sortable?
      !reorder? && attributes[:sortable] != false
    end

    def searchable?
      attributes[:searchable] != false
    end

    def downloadable?
      attributes[:downloadable] != false
    end

    # Whether the filters must be rendered as a <form> or we can keep the normal <div> behaviour
    def _filters_form_required?
      _form[:verb].present?
    end

    def html_class
      Array(attributes[:class] || EffectiveDatatables.html_class).join(' ').presence
    end

    def to_param
      "#{self.class.name.underscore.parameterize}-#{[self.class, attributes].hash.abs.to_s.last(12)}"
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

    def resource
      raise('depecated. Please use .effective_resource instead')
    end

    def fallback_effective_resource
      @fallback_effective_resource ||= Effective::Resource.new('', namespace: controller_namespace)
    end

    def default_visibility
      columns.values.inject({}) { |h, col| h[col[:index]] = col[:visible]; h }
    end

    private

    def column_tool
      @column_tool ||= DatatableColumnTool.new(self)
    end

    def value_tool
      @value_tool ||= DatatableValueTool.new(self)
    end

    def validate_datatable!
      if reorder?
        raise 'cannot use reorder with an Array collection' unless active_record_collection?
        raise 'cannot use reorder with a non-Integer column' if effective_resource.sql_type(columns[:_reorder][:reorder]) != :integer
      end
    end

  end
end

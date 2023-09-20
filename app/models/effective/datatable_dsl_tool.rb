# frozen_string_literal: true

module Effective

  class DatatableDslTool
    attr_reader :datatable
    attr_reader :view

    attr_accessor :in_datatables_do_block

    include Effective::EffectiveDatatable::Dsl::BulkActions
    include Effective::EffectiveDatatable::Dsl::Charts
    include Effective::EffectiveDatatable::Dsl::Datatable
    include Effective::EffectiveDatatable::Dsl::Filters

    def initialize(datatable)
      @datatable = datatable
      @view = datatable.view
    end

    def method_missing(method, *args, **kwargs, &block)
      # Catch a common error
      if [:bulk_actions, :charts, :collection, :filters].include?(method) && in_datatables_do_block
        raise "#{method} block must be declared outside the datatable do ... end block"
      end

      subject = datatable if datatable.respond_to?(method)
      subject ||= view if view.respond_to?(method)
      subject ||= Tenant.helpers if defined?(Tenant) && Tenant.helpers.respond_to?(method)

      return super unless subject

      if block_given?
        subject.send(method, *args, **kwargs) { yield }
      else
        subject.send(method, *args, **kwargs)
      end
    end

  end
end

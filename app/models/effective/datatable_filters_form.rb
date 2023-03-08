# Form Object for the filters form

module Effective
  class DatatableFiltersForm
    include ActiveModel::Model

    attr_accessor :scope

    def initialize(datatable:)
      # Assign the current value of scope
      assign_attributes(scope: datatable.state[:scope])

      # Create an attr_accesor for each filter and assign value
      datatable._filters.each do |name, options|
        self.class.send(:attr_accessor, name)
        assign_attributes(name => datatable.state[:filter][name])
      end
    end

  end
end

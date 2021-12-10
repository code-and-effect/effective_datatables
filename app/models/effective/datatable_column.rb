# frozen_string_literal: true

# In practice this is just a regular hash with the aggregate, format, search, sort do syntax that saves a block
module Effective
  class DatatableColumn
    attr_accessor :attributes

    delegate :[], :[]=, to: :attributes

    def initialize(attributes)
      @attributes = attributes
    end

    def to_s
      self[:name]
    end

    def aggregate(&block)
      @attributes[:aggregate] = block; self
    end

    def format(&block)
      @attributes[:format] = block; self
    end

    def search(&block)
      @attributes[:search_method] = block; self
    end

    def sort(&block)
      @attributes[:sort_method] = block; self
    end

  end
end

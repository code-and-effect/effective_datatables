module Effective
  class DatatableColumn
    attr_accessor :attributes

    delegate :[], :[]=, to: :attributes

    def initialize(attributes)
      @attributes = attributes
    end

    def format(&block)
      raise 'expecting a block' unless block_given?

      @attributes[:format] = block
    end

  end
end

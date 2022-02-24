# frozen_string_literal: true

module Effective
  # The collection is an Array of Arrays
  class DatatableValueTool
    attr_reader :datatable
    attr_reader :columns

    def initialize(datatable)
      @datatable = datatable

      if datatable.array_collection?
        @columns = datatable.columns
      else
        @columns = datatable.columns.select { |_, col| col[:sql_column].blank? }
      end
    end

    def searched
      @searched ||= datatable.search.select { |name, _| columns.key?(name) }
    end

    def ordered
      @ordered ||= columns[datatable.order_name]
    end

    def order(collection)
      return collection unless ordered.present?

      collection = if ordered[:sort_method]
        datatable.dsl_tool.instance_exec(collection, datatable.order_direction, ordered, ordered[:index], &ordered[:sort_method])
      else
        order_column(collection, datatable.order_direction, ordered, ordered[:index])
      end

      raise 'sort method must return an Array' unless collection.kind_of?(Array)

      collection
    end

    def order_column(collection, direction, column, index)
      Rails.logger.info "VALUE TOOL: order_column :#{column.to_s} :#{direction} #{index}" if EffectiveDatatables.debug

      if direction == :asc
        collection.sort! do |x, y|
          x = obj_to_value(x[index], column)
          y = obj_to_value(y[index], column)

          x <=> y || x.to_s <=> y.to_s || 0
        end
      else
        collection.sort! do |x, y|
          x = obj_to_value(x[index], column)
          y = obj_to_value(y[index], column)

          y <=> x || y.to_s <=> x.to_s || 0
        end
      end

      collection
    end

    def search(collection)
      searched.each do |name, value|
        column = columns[name]

        collection = if column[:search_method]
          datatable.dsl_tool.instance_exec(collection, value, column, column[:index], &column[:search_method])
        else
          search_column(collection, value, column, column[:index])
        end

        raise 'search method must return an Array object' unless collection.kind_of?(Array)
      end

      collection
    end

    def search_column(collection, original, column, index)
      Rails.logger.info "VALUE TOOL: search_column #{column.to_s} #{original} #{index}" if EffectiveDatatables.debug

      fuzzy = column[:search][:fuzzy]

      term = Effective::Attribute.new(column[:as]).parse(original, name: column[:name])
      term_downcased = term.to_s.downcase

      # term == 'nil' rescue false is a Rails 4.1 fix, where you can't compare a TimeWithZone to 'nil'
      if (term == 'nil' rescue false)
        return collection.select! { |row| obj_to_value(row[index], column, row) == nil } || collection
      end

      # See effective_resources gem search() method # relation.rb
      collection.select! do |row|
        obj = row[index]
        value = obj_to_value(row[index], column, row)

        case column[:as]
        when :boolean
          if fuzzy
            term ? (obj == true) : (obj != true)
          else
            obj == term
          end
        when :datetime, :date
          end_at = (
            case (original.to_s.scan(/(\d+)/).flatten).length
            when 1 ; term.end_of_year     # Year
            when 2 ; term.end_of_month    # Year-Month
            when 3 ; term.end_of_day      # Year-Month-Day
            when 4 ; term.end_of_hour     # Year-Month-Day Hour
            when 5 ; term.end_of_minute   # Year-Month-Day Hour-Minute
            when 6 ; term + 1.second      # Year-Month-Day Hour-Minute-Second
            else term
            end
          )
          value >= term && value <= end_at
        when :time
          (value.hour == term.hour) && (term.min == 0 ? true : (value.min == term.min))
        when :decimal, :currency
          if fuzzy && (term.round(0) == term) && original.to_s.include?('.') == false
            if term < 0
              value <= term && value > (term - 1.0)
            else
              value >= term && value < (term + 1.0)
            end
          else
            value == term
          end
        when :duration
          if fuzzy && (term % 60 == 0) && original.to_s.include?('m') == false
            if term < 0
              value <= term && value > (term - 60)
            else
              value >= term && value < (term + 60)
            end
          else
            value == term
          end
        when *datatable.association_macros, :resource
          Array(obj).any? do |resource|
            Array(term).any? do |term|
              matched = false

              if term.kind_of?(Integer) && resource.respond_to?(:id) && resource.respond_to?(:to_param)
                matched = (resource.id == term || resource.to_param == term)
              end

              matched ||= (fuzzy ? resource.to_s.downcase.include?(term.to_s.downcase) : resource.to_s == term)
            end
          end
        else  # :string, :text, :email
          if fuzzy
            value.to_s.downcase.include?(term_downcased)
          else
            value == term || (value.to_s == term.to_s)
          end
        end
      end || collection
    end

    def paginate(collection)
      page = [datatable.page.to_i - 1, 0].max
      per_page = datatable.per_page.to_i

      collection[(page * per_page)...((page * per_page) + per_page)]
    end

    def size(collection)
      collection.size
    end

    def obj_to_value(obj, column, row = nil)
      return obj if column[:compute]

      # This matches format.rb.  Probably should be refactored.

      if column[:format]
        datatable.dsl_tool.instance_exec(obj, row, &column[:format])
      elsif column[:as] == :belongs_to_polymorphic
        obj.send(column[:name]).to_s
      elsif column[:partial]
        obj.to_s
      elsif obj.respond_to?(column[:name])
        obj.send(column[:name])
      elsif column[:as] == :time && obj.respond_to?(:strftime)
        (@_column_as_time ||= Time.zone.now.beginning_of_day) + ((1.hour * obj.hour) + (1.minute * obj.min)) # For search/order by time
      else
        obj
      end
    end

  end
end

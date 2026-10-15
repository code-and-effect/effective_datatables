# frozen_string_literal: true

module Effective
  class DatatableColumnTool
    attr_reader :datatable
    attr_reader :columns

    def initialize(datatable)
      @datatable = datatable

      if datatable.active_record_collection?
        @columns = datatable.columns.select { |_, col| col[:sql_column].present? || (col[:search_method].present? && col[:sql_column] != false) }
      else
        @columns = {}
      end
    end

    def scoped
      @scoped ||= datatable._scopes[datatable.scope]
    end

    def searched
      @searched ||= datatable.search.select { |name, _| columns.key?(name) }
    end

    def ordered
      @ordered_column ||= columns[datatable.order_name]
    end

    def order(collection)
      return collection unless ordered.present?

      collection = if ordered[:sort_method]
        datatable.dsl_tool.instance_exec(collection, datatable.order_direction, ordered, ordered[:sql_column], &ordered[:sort_method])
      else
        order_column(collection, datatable.order_direction, ordered, ordered[:sql_column])
      end

      raise 'sort method must return an ActiveRecord::Relation object' unless collection.kind_of?(ActiveRecord::Relation)

      collection
    end

    def order_column(collection, direction, column, sql_column)
      Rails.logger.info "COLUMN TOOL: order_column #{column.to_s} #{direction} #{sql_column}" if EffectiveDatatables.debug

      if column[:as] == :reorder && sql_column == column[:reorder]
        attribute = collection.arel_table[column[:reorder]]
        collection.order(direction.to_s.downcase == 'desc' ? attribute.desc : attribute.asc)
      elsif column[:sql_as_column]
        expression = Arel.sql(sql_column.to_s)
        collection.order(direction.to_s.downcase == 'desc' ? expression.desc : expression.asc)
      else
        Effective::Resource.new(collection)
          .order(column[:name], direction, as: column[:as], sort: column[:sort], sql_column: column[:sql_column], limit: datatable.limit)
      end
    end

    def scope(collection)
      return collection unless scoped.present?

      collection.send(scoped[:name], *scoped[:args])
    end

    def search(collection)
      searched.each do |name, value|
        column = columns[name]

        collection = if column[:search_method]
          datatable.dsl_tool.instance_exec(collection, value, column, column[:sql_column], &column[:search_method])
        else
          search_column(collection, value, column, column[:sql_column])
        end

        raise 'search method must return an ActiveRecord::Relation object' unless collection.kind_of?(ActiveRecord::Relation)
      end

      collection
    end

    def search_column(collection, value, column, sql_column)
      Rails.logger.info "COLUMN TOOL: search_column #{column.to_s} value=#{value} operation=#{column[:search][:operation]} column=#{sql_column}" if EffectiveDatatables.debug

      Effective::Resource.new(collection)
        .search(column[:name], value, as: column[:as], operation: column[:search][:operation], column: sql_column)
    end

    def paginate(collection)
      collection.limit(datatable.limit).offset(datatable.offset)
    end

    # Not every ActiveRecord query will work when calling the simple .count
    # Custom selects:
    #   User.select(:email, :first_name).count will throw an error
    # Grouped Queries:
    #   User.all.group(:email).count will return a Hash
    def size(collection)
      count = (collection.size rescue nil)

      case count
      when Integer
        count
      when Hash
        count.size  # This represents the number of displayed datatable rows, not the sum all groups (which might be more)
      else
        (collection.klass.unscoped.from(collection, :datatables_total_count).count(:all) rescue 1).to_i
      end
    end

  end
end

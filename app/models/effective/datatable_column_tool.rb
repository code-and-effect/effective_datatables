module Effective
  class DatatableColumnTool
    attr_reader :datatable
    attr_reader :columns
    attr_reader :resource

    def initialize(datatable)
      @datatable = datatable
      @resource = datatable.resource

      if datatable.active_record_collection?
        @columns = datatable.columns.select { |_, col| col[:sql_column].present? }
      else
        @columns = {}
      end
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
        if collection.klass.connection.respond_to?(:unprepared_statement)
          collection_sql = collection.klass.connection.unprepared_statement { collection.to_sql }
          (collection.klass.connection.exec_query("SELECT COUNT(*) FROM (#{collection_sql}) AS datatables_total_count").rows[0][0] rescue 1)
        else
          (collection.klass.connection.exec_query("SELECT COUNT(*) FROM (#{collection.to_sql}) AS datatables_total_count").rows[0][0] rescue 1)
        end.to_i
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

      collection = datatable.order_column(collection, ordered, datatable.order_direction, ordered[:sql_column])
      raise 'order_column must return an ActiveRecord::Relation object' unless collection.kind_of?(ActiveRecord::Relation)
      collection
    end

    def order_column(collection, column, direction, sql_column)
      Rails.logger.info "COLUMN TOOL: order_column #{column} #{direction} #{sql_column}"

      if column[:sql_as_column]
        collection.order("#{sql_column} #{resource.sql_direction(direction)}")
      else
        Effective::Resource.new(collection)
          .order(column[:name], direction, as: column[:as], sort: column[:sort], sql_column: column[:sql_as_column])
      end
    end

    def scope(collection)
      return collection unless scoped.present?

      collection.send(scoped[:name], *scoped[:args])
    end

    def search(collection)
      searched.each do |name, value|
        column = columns[name]

        if column[:search_method]
          collection = datatable.dsl_tool.instance_exec(collection, value, column, column[:sql_column], &column[:search_method])
        else
          collection = search_column(collection, value, column, column[:sql_column])
        end

        raise 'search_column must return an ActiveRecord::Relation object' unless collection.kind_of?(ActiveRecord::Relation)
      end

      collection
    end

    def search_column(collection, value, column, sql_column)
      Rails.logger.info "COLUMN TOOL: search_column #{column} #{value} #{sql_column}"

      Effective::Resource.new(collection)
        .search(column[:name], value, as: column[:as], fuzzy: column[:search][:fuzzy], sql_column: sql_column)
    end

    def paginate(collection)
      collection.page(datatable.page).per(datatable.per_page)
    end

  end
end

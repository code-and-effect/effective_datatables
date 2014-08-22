module Effective
  class Datatable
    attr_accessor :total_records, :display_records, :view, :attributes

    delegate :render, :link_to, :mail_to, :to => :@view

    class << self
      def all
        EffectiveDatatables.datatables.map { |klass| klass.new() }
      end

      def find(obj, attributes = nil)
        obj = obj.respond_to?(:to_param) ? obj.to_param : obj
        EffectiveDatatables.datatables.find { |klass| klass.name.underscore.parameterize == obj }.try(:new, attributes || {})
      end

      def table_column(name, options = {}, proc = nil, &block)
        if block_given?
          raise "You cannot use :partial => '' with the block syntax" if options[:partial]
          raise "You cannot use :proc => ... with the block syntax" if options[:proc]
          options[:block] = block
        end
        raise "You cannot use both :partial => '' and proc => ..." if options[:partial] && options[:proc]

        (@table_columns ||= HashWithIndifferentAccess.new())[name] = options
      end

      def table_columns(*names)
        names.each { |name| table_column(name) }
      end

      def array_column(name, options = {}, proc = nil, &block)
        table_column(name, options.merge({:array_column => true}), proc, &block)
      end

      def array_columns(*names)
        names.each { |name| array_column(name) }
      end

      def default_order(name, direction = :asc)
        @default_order = {name => direction}
      end
    end

    def initialize(*args)
      if args.present?
        raise 'Effective::Datatable.new() can only be called with a Hash like arguments' unless args.first.kind_of?(Hash)
        args.first.each { |k, v| self.attributes[k] = v }
      end

      unless active_record_collection? || collection.kind_of?(Array)
        raise 'Unsupported collection type. Should be ActiveRecord class, ActiveRecord relation, or Array'
      end
    end

    # Any attributes set on initialize will be echoed back and available to the class
    def attributes
      @attributes ||= HashWithIndifferentAccess.new()
    end

    def to_param
      self.class.name.underscore.parameterize
    end

    def collection
      raise 'You must define a collection. Something like User.scoped'
    end

    def finalize(collection) # Override me if you like
      collection
    end

    def table_columns
      table_columns_with_defaults()
    end

    def to_json(options = {})
      {
        :sEcho => params[:sEcho].to_i,
        :aaData => table_data || [],
        :iTotalRecords => (
          unless total_records.kind_of?(Hash)
            total_records.to_i
          else
            (total_records.keys.map(&:first).uniq.count rescue 1)
          end),
        :iTotalDisplayRecords => (
          unless display_records.kind_of?(Hash)
            display_records.to_i
          else
            (display_records.keys.map(&:first).uniq.count rescue 1)
          end)
      }
    end

    # Wish these were protected

    def order_column_index
      params[:iSortCol_0].to_i
    end

    def order_direction
      params[:sSortDir_0].try(:downcase) == 'desc' ? 'DESC' : 'ASC'
    end

    def default_order
      self.class.instance_variable_get(:@default_order)
    end

    def search_terms
      @search_terms ||= HashWithIndifferentAccess.new().tap do |terms|
        table_columns.keys.each_with_index do |col, x|
          unless (params["sVisible_#{x}"] == 'false' && table_columns[col][:filter][:when_hidden] != true)
            terms[col] = params["sSearch_#{x}"] if params["sSearch_#{x}"].present?
          end
        end
      end
    end

    # This is here so classes that inherit from Datatables can can override the specific where clauses on a search column
    def search_column(collection, table_column, search_term)
      if table_column[:array_column]
        array_tool.search_column_with_defaults(collection, table_column, search_term)
      else
        table_tool.search_column_with_defaults(collection, table_column, search_term)
      end
    end

    def per_page
      length = params[:iDisplayLength].to_i

      if length == -1
        9999999
      elsif length > 0
        length
      else
        10
      end
    end

    def page
      params[:iDisplayStart].to_i / per_page + 1
    end

    protected

    # So the idea here is that we want to do as much as possible on the database in ActiveRecord
    # And then run any array_columns through in post-processed results
    def table_data
      c = collection

      if active_record_collection?
        self.total_records = (c.select('*').reorder(nil).count rescue 1)

        c = table_tool.order(c)
        c = table_tool.search(c)

        if table_tool.search_terms.present? && array_tool.search_terms.blank?
          self.display_records = (c.select('*').reorder(nil).count rescue 1)
        end
      else
        self.total_records = c.size
      end

      if array_tool.search_terms.present?
        c = self.arrayize(c)
        c = array_tool.search(c)
        self.display_records = c.size
      end

      if array_tool.order_column.present?
        c = self.arrayize(c)
        c = array_tool.order(c)
      end

      self.display_records ||= total_records

      if c.kind_of?(Array)
        c = array_tool.paginate(c)
      else
        c = table_tool.paginate(c)
        c = self.arrayize(c)
      end

      c = self.finalize(c)
    end

    def arrayize(collection)
      return collection if @arrayized  # Prevent the collection from being arrayized more than once
      @arrayized = true

      # We want to use the render :collection for each column that renders partials
      rendered = {}
      table_columns.each do |name, opts|
        if opts[:partial]
          rendered[name] = (render(
            :partial => opts[:partial],
            :as => opts[:partial_local],
            :collection => collection,
            :formats => :html,
            :locals => {:datatable => self},
            :spacer_template => '/effective/datatables/spacer_template',
          ) || '').split('EFFECTIVEDATATABLESSPACER')
        end
      end

      collection.each_with_index.map do |obj, index|
        table_columns.map do |name, opts|
          if opts[:partial]
            rendered[name][index]
          elsif opts[:block]
            view.instance_exec(obj, collection, self, &opts[:block])
          elsif opts[:proc]
            view.instance_exec(obj, collection, self, &opts[:proc])
          else
            value = obj.send(name) rescue ''

            # Last minute formatting of dates
            case value
            when Date
              value.strftime("%Y-%m-%d")
            when Time
              value.strftime("%Y-%m-%d %H:%M")
            when DateTime
              value.strftime("%Y-%m-%d %H:%M")
            else
              value
            end

          end
        end
      end
    end

    private

    def params
      view.try(:params) || HashWithIndifferentAccess.new()
    end

    def table_tool
      @table_tool ||= ActiveRecordDatatableTool.new(self, table_columns.select { |_, col| col[:array_column] == false })
    end

    def array_tool
      @array_tool ||= ArrayDatatableTool.new(self, table_columns.select { |_, col| col[:array_column] == true })
    end

    def active_record_collection?
      @active_record_collection ||= (collection.ancestors.include?(ActiveRecord::Base) rescue false)
    end

    def table_columns_with_defaults
      unless self.class.instance_variable_get(:@table_columns_initialized)
        self.class.instance_variable_set(:@table_columns_initialized, true)
        initalize_table_columns(self.class.instance_variable_get(:@table_columns))
      end
      self.class.instance_variable_get(:@table_columns)
    end

    def initalize_table_columns(cols)
      sql_table = (collection.table rescue nil)
      index = -1

      cols.each do |name, _|
        sql_column = (collection.columns rescue []).find { |column| column.name == name.to_s }

        cols[name][:index] = (index += 1)  # So first one is assigned 0
        cols[name][:array_column] ||= false

        cols[name][:name] ||= name
        cols[name][:label] ||= name.titleize
        cols[name][:column] ||= (sql_table && sql_column) ? "\"#{sql_table.name}\".\"#{sql_column.name}\"" : name
        cols[name][:type] ||= sql_column.try(:type) || :string
        cols[name][:width] ||= nil
        cols[name][:sortable] = true if cols[name][:sortable] == nil
        cols[name][:filter] = initialize_table_column_filter(cols[name][:filter], cols[name][:type])

        if cols[name][:partial]
          cols[name][:partial_local] ||= (sql_table.try(:name) || cols[name][:partial].split('/').last(2).first.presence || 'obj').singularize.to_sym
        end
      end

    end

    def initialize_table_column_filter(filter, col_type)
      return {:type => :null, :when_hidden => false} if filter == false

      if filter.kind_of?(Symbol)
        filter = {:type => filter}
      elsif filter.kind_of?(String)
        filter = {:type => filter.to_sym}
      elsif filter.kind_of?(Hash) == false
        filter = {}
      end

      case col_type # null, number, select, number-range, date-range, checkbox, text(default)
      when :integer
        {:type => :number, :when_hidden => false}.merge(filter)
      when :boolean
        {:type => :select, :when_hidden => false, :values => [true, false]}.merge(filter)
      else
        {:type => :text, :when_hidden => false}.merge(filter)
      end
    end

  end
end

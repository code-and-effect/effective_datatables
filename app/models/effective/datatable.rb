module Effective
  class Datatable
    cattr_accessor :view
    attr_accessor :total_records, :display_records

    delegate :params, :render, :link_to, :to => :@view

    class << self
      def all
        EffectiveDatatables.datatables.map { |klass| klass.new() }
      end

      def find(obj)
        obj = obj.respond_to?(:to_param) ? obj.to_param : obj
        EffectiveDatatables.datatables.find { |klass| klass.name.underscore.parameterize == obj }.try(:new)
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
    end

    def view=(view)
      @view = view
      extend_datatable_finders()
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

    protected

    def table_data
      c = collection
      self.total_records = (c.select('*').reorder(nil).count rescue 1)

      c = order(c)
      c = search(c)
      self.display_records = search_terms.any? { |k, v| v.present? } ? (c.select('*').reorder(nil).count rescue 1): total_records

      c = paginate(c)
      c = finalize(c)
      c = arrayize(c)
    end

    def order_column
      params[:iSortCol_0].to_i
    end

    def order_direction
      params[:sSortDir_0].try(:downcase) == 'desc' ? 'DESC' : 'ASC'
    end

    def search_terms
      @search_terms ||= HashWithIndifferentAccess.new().tap do |terms|
        table_columns.keys.each_with_index { |col, x| terms[col] = params["sSearch_#{x}"] }
      end
    end

    # This is here so I can override the specific where clauses on a search column
    def search_column(collection, table_column, search_term)
      search_column_with_defaults(collection, table_column, search_term)
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

    private

    def extend_datatable_finders
      if active_record_collection?
        extend ActiveRecordDatatable
      elsif collection.kind_of?(Array)
        extend ArrayDatatable
      else
        raise 'Unsupported collection type. Should be ActiveRecord class, ActiveRecord relation, or Array'
      end
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
      return unless active_record_collection?

      sql_table = (collection.table rescue nil)

      cols.each do |name, _|
        sql_column = (collection.columns rescue []).find { |column| column.name == name.to_s }

        cols[name][:name] ||= name
        cols[name][:label] ||= name.titleize
        cols[name][:column] ||= (sql_table && sql_column) ? "\"#{sql_table.name}\".\"#{sql_column.name}\"" : name
        cols[name][:type] ||= sql_column.try(:type) || :string
        cols[name][:sortable] = true if cols[name][:sortable] == nil

        if cols[name][:filter].kind_of?(Symbol) || cols[name][:filter].kind_of?(String)
          cols[name][:filter] = {:type => cols[name][:filter]} 
        elsif cols[name][:filter] == false
          cols[name][:filter] = {:type => :null} 
        elsif cols[name][:filter] == true
          cols[name][:filter] = nil
        end

        cols[name][:filter] ||= 
          case cols[name][:type] # null, number, select, number-range, date-range, checkbox, text(default)
            when :integer   ; {:type => :number}
            when :boolean   ; {:type => :select, :values => [true, false]}
            else            ; {:type => :text}
          end

        if cols[name][:partial]
          cols[name][:partial_local] ||= (sql_table.try(:name) || cols[name][:partial].split('/').last(2).first.presence || 'obj').singularize.to_sym
        end

      end
    end
  end
end

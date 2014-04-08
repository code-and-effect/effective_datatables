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

      def table_column(name, options = {})
        (@table_columns ||= {})[name.to_s.downcase] = options
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
        :iTotalRecords => total_records.to_i,
        :iTotalDisplayRecords => display_records.to_i,
      }
    end

    protected

    def table_data
      c = collection
      self.total_records = (c.select('*').count rescue c.count)

      c = order(c)
      c = search(c)
      self.display_records = search_terms.any? { |k, v| v.present? } ? (c.select('*').count rescue c.count) : total_records

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
      @search_terms ||= {}.tap do |terms|
        table_columns.keys.each_with_index { |col, x| terms[col] = params["sSearch_#{x}"] }
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

        cols[name][:label] ||= name.titleize
        cols[name][:column] ||= (sql_table && sql_column) ? "\"#{sql_table.name}\".\"#{sql_column.name}\"" : name
        cols[name][:type] ||= sql_column.try(:type) || :string
        cols[name][:sortable] = true if cols[name][:sortable] == nil
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

module EffectiveDatatablesHelper
  def render_datatable(datatable, opts = {})
    datatable.view = self
    locals = {:style => :full, :filterable => true, :sortable => true, :table_class => 'table-bordered table-striped'}.merge(opts)
    locals[:table_class] = 'sorting-hidden ' + locals[:table_class].to_s if locals[:sortable] == false

    render :partial => 'effective/datatables/datatable', :locals => locals.merge(:datatable => datatable)
  end

  def render_simple_datatable(datatable, opts = {})
    datatable.view = self
    locals = {:style => :simple, :filterable => false, :sortable => false, :table_class => ''}.merge(opts)
    locals[:table_class] = 'sorting-hidden ' + locals[:table_class].to_s if locals[:sortable] == false

    render :partial => 'effective/datatables/datatable', :locals => locals.merge(:datatable => datatable)
  end

  def datatable_filter(datatable, filterable = true)
    return false unless filterable

    filters = datatable.table_columns.values.map { |options, _| options[:filter] || {:type => 'null'} }

    # Process any Procs
    filters.each do |filter|
      if filter[:values].respond_to?(:call)
        filter[:values] = filter[:values].call()

        if filter[:values].kind_of?(ActiveRecord::Relation) || (filter[:values].kind_of?(Array) && filter[:values].first.kind_of?(ActiveRecord::Base))
          filter[:values] = filter[:values].map { |obj| [obj.id, obj.to_s] }
        end
      end
    end

    filters.to_json()
  end

  def datatable_non_sortable(datatable, sortable = true)
    [].tap do |nonsortable|
      datatable.table_columns.values.each_with_index { |options, x| nonsortable << x if options[:sortable] == false || sortable == false }
    end.to_json()
  end

  def datatable_non_visible(datatable)
    [].tap do |nonvisible|
      datatable.table_columns.values.each_with_index { |options, x| nonvisible << x if options[:visible] == false }
    end.to_json()
  end

  def datatable_default_order(datatable)
    [
      if datatable.default_order.present?
        index = (datatable.table_columns.values.find { |options| options[:name] == datatable.default_order.keys.first.to_s }[:index] rescue nil)
        [index, datatable.default_order.values.first] if index.present?
      end || [0, 'asc']
    ].to_json()
  end

  def datatable_widths(datatable)
    datatable.table_columns.values.map { |options| {'sWidth' => options[:width]} if options[:width] }.to_json()
  end


end

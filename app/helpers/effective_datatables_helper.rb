module EffectiveDatatablesHelper
  def render_datatable(datatable, opts = {}, &block)
    datatable.view = self

    locals = {:style => :full, :filterable => true, :sortable => true, :table_class => 'table-bordered table-striped'}
    locals = locals.merge(opts) if opts.kind_of?(Hash)
    locals[:table_class] = 'sorting-hidden ' + locals[:table_class].to_s if locals[:sortable] == false

    # Do we have to look at empty? behaviour
    if (block_given? || opts.kind_of?(String) || (opts.kind_of?(Hash) && opts[:empty].present?)) && datatable.empty?
      if block_given?
        yield; nil
      elsif opts.kind_of?(String)
        opts
      elsif opts.kind_of?(Hash) && opts[:empty].present?
        opts[:empty]
      end
    else
      render :partial => 'effective/datatables/datatable', :locals => locals.merge(:datatable => datatable)
    end
  end

  def render_simple_datatable(datatable, opts = {})
    datatable.view = self
    locals = {:style => :simple, :filterable => false, :sortable => false, :table_class => ''}.merge(opts)
    locals[:table_class] = 'sorting-hidden ' + locals[:table_class].to_s if locals[:sortable] == false

    render :partial => 'effective/datatables/datatable', :locals => locals.merge(:datatable => datatable)
  end

  def render_datatable_header_cell(form, name, opts)
    case opts[:filter][:type]
    when :string, :text, :number
      form.input name, :label => false, :required => false,
        :input_html => {
          :autocomplete => 'off',
          :data => {:index => opts[:index]}
        },
        :as => :string, :placeholder => (opts[:label] || name)
    when :select, :boolean
      form.input name, :label => false, :required => false,
        :input_html => {
          :autocomplete => 'off',
          :data => {:index => opts[:index]}
        },
        :as => :select, :collection => opts[:filter][:values], :include_blank => (opts[:label] || name.titleize)
    else
      content_tag(:p, opts[:label] || name)
    end

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
      datatable.table_columns.values.each_with_index do |options, x|
        visible = (options[:visible].respond_to?(:call) ? datatable.instance_exec(&options[:visible]) : options[:visible])
        nonvisible << x if visible == false
      end
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

  def datatable_column_classes(datatable)
    [].tap do |classes|
      datatable.table_columns.values.each_with_index do |options, x|
        classes << {:className => options[:class], :targets => [x]} if options[:class].present?
      end
    end.to_json()
  end

  def datatable_column_names(datatable)
    datatable.table_columns.values.map { |options| {:name => options[:name], :targets => options[:index] } }.to_json()
  end

  def datatables_admin_path?
    @datatables_admin_path ||= (
      path = request.path.to_s.downcase.chomp('/') + '/'
      referer = request.referer.to_s.downcase.chomp('/') + '/'
      (attributes[:admin_path] || referer.include?('/admin/') || path.include?('/admin/')) rescue false
    )
  end

  # TODO: Improve on this
  def datatables_active_admin_path?
    attributes[:active_admin_path] rescue false
  end

end

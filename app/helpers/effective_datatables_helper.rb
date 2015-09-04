module EffectiveDatatablesHelper
  def render_datatable(datatable, opts = {}, &block)
    datatable.view = self
    locals = {style: :full, filterable: true, sortable: true, table_class: 'table-bordered table-striped'}.merge(opts)

    render partial: 'effective/datatables/datatable', locals: locals.merge(datatable: datatable)
  end

  def render_simple_datatable(datatable, opts = {})
    datatable.view = self
    datatable.per_page = :all
    locals = {style: :simple, filterable: false, sortable: false, table_class: 'table-bordered table-striped sorting-hidden'}.merge(opts)

    render partial: 'effective/datatables/datatable', locals: locals.merge(datatable: datatable)
  end

  def render_datatable_header_cell(form, name, opts, filterable = true)
    return render(partial: opts[:header_partial], locals: {form: form, name: (opts[:label] || name), column: opts, filterable: filterable}) if opts[:header_partial].present?
    return content_tag(:p, opts[:label] || name) if filterable == false

    case opts[:filter][:type]
    when :string, :text, :number
      form.input name, label: false, required: false, as: :string, placeholder: (opts[:label] || name),
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} }
    when :date
      form.input name, label: false, required: false,
        as: (defined?(EffectiveFormInputs) ? :effective_date_picker : :string),
        placeholder: (opts[:label] || name),
        input_group: false,
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} }
    when :datetime
      form.input name, label: false, required: false,
        as: (defined?(EffectiveFormInputs) ? :effective_date_time_picker : :string),
        placeholder: (opts[:label] || name),
        input_group: false,
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} }

    when :select, :boolean
      if opts[:filter][:values].respond_to?(:call)
        opts[:filter][:values] = opts[:filter][:values].call()

        if opts[:filter][:values].kind_of?(ActiveRecord::Relation) || (opts[:filter][:values].kind_of?(Array) && opts[:filter][:values].first.kind_of?(ActiveRecord::Base))
          opts[:filter][:values] = opts[:filter][:values].map { |obj| [obj.to_s, obj.to_param] }
        end
      end

      form.input name, label: false, required: false,
        as: (defined?(EffectiveFormInputs) ? :effective_select : :select),
        collection: opts[:filter][:values],
        multiple: opts[:filter][:multiple] == true,
        include_blank: (opts[:label] || name.titleize),
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { placeholder: (opts[:label] || name.titleize) }
    when :grouped_select
      raise "Expected :group_select filter to define its values as a Hash {'Posts' => Post.all, 'Events' => Event.all} or a Hash {'Posts' => [['Post A', 1], ['Post B', 2]], 'Events' => [['Event A', 1], ['Event B', 2]]}" unless opts[:filter][:values].kind_of?(Hash)

      opts[:filter][:values].each do |group, options|
        if options.kind_of?(ActiveRecord::Relation)
          if opts[:type] == :belongs_to_polymorphic
            opts[:filter][:values][group] = options.map { |obj| [obj.to_s, "#{options.model_name}_#{obj.to_param}"] }
          else
            opts[:filter][:values][group] = options.map { |obj| [obj.to_s, obj.to_param] }
          end
        end
      end

      form.input name, label: false, required: false,
        as: (defined?(EffectiveFormInputs) ? :effective_select : :grouped_select),
        collection: opts[:filter][:values],
        multiple: opts[:filter][:multiple] == true,
        include_blank: (opts[:label] || name.titleize),
        grouped: true,
        group_label_method: :first,
        group_method: :last,
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { placeholder: (opts[:label] || name.titleize) }
    else
      content_tag(:p, opts[:label] || name)
    end
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
    [datatable.order_index, datatable.order_direction.downcase].to_json()
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

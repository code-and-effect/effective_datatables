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

  def datatable_default_order(datatable)
    [datatable.order_index, datatable.order_direction.downcase].to_json()
  end

  # https://datatables.net/reference/option/columns
  def datatable_columns(datatable)
    form_builder = nil
    simple_form_for(datatable, url: '#', html: {id: "#{datatable.to_param}-form"}) { |f| form_builder = f }

    datatable.table_columns.map do |name, options|
      {
        name: options[:name],
        title: options[:label],
        className: options[:class],
        width: options[:width],
        responsivePriority: (options[:responsivePriority] || 10000),  # 10,000 is datatables default
        sortable: options[:sortable],
        visible: (options[:visible].respond_to?(:call) ? datatable.instance_exec(&options[:visible]) : options[:visible]),
        filterHtml: datatable_header_filter(form_builder, name, options),
        filterSelectedValue: options[:filter][:selected]
      }
    end.to_json()
  end

  def datatable_header_filter(form, name, opts, filterable = true)
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
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { useStrict: true, keepInvalid: true }
    when :datetime
      form.input name, label: false, required: false,
        as: (defined?(EffectiveFormInputs) ? :effective_date_time_picker : :string),
        placeholder: (opts[:label] || name),
        input_group: false,
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { useStrict: true, keepInvalid: true } # Keep invalid format like "2015-11" so we can still filter by year, month or day
    when :select, :boolean
      form.input name, label: false, required: false,
        as: (defined?(EffectiveFormInputs) ? :effective_select : :select),
        collection: opts[:filter][:values],
        multiple: opts[:filter][:multiple] == true,
        include_blank: (opts[:label] || name.titleize),
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { placeholder: (opts[:label] || name.titleize) }
    when :grouped_select
      form.input name, label: false, required: false,
        as: (defined?(EffectiveFormInputs) ? :effective_select : :grouped_select),
        collection: opts[:filter][:values],
        multiple: opts[:filter][:multiple] == true,
        include_blank: (opts[:label] || name.titleize),
        grouped: true,
        polymorphic: opts[:filter][:polymorphic] == true,
        group_label_method: opts[:filter][:group_label_method] || :first,
        group_method: opts[:filter][:group_method] || :last,
        input_html: { name: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { placeholder: (opts[:label] || name.titleize) }
    else
      content_tag(:p, opts[:label] || name)
    end
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

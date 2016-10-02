# These aren't expected to be called by a developer.
# They are internal datatables methods, but you could still call them on the view.
module EffectiveDatatablesPrivateHelper

  def datatable_default_order(datatable)
    [datatable.order_index, datatable.order_direction.downcase].to_json()
  end

  # https://datatables.net/reference/option/columns
  def datatable_columns(datatable)
    form = nil
    simple_form_for(:datatable_filter, url: '#', html: {id: "#{datatable.to_param}-form"}) { |f| form = f }

    datatable.table_columns.map do |name, options|
      {
        name: options[:name],
        title: content_tag(:span, options[:label], class: 'filter-label'),
        className: options[:class],
        width: options[:width],
        responsivePriority: (options[:responsivePriority] || 10000),  # 10,000 is datatables default
        sortable: (options[:sortable] && !datatable.simple?),
        visible: (options[:visible].respond_to?(:call) ? datatable.instance_exec(&options[:visible]) : options[:visible]),
        filterHtml: (datatable_header_filter(form, name, datatable.search_terms[name], options) unless datatable.simple?),
        filterSelectedValue: options[:filter][:selected]
      }
    end.to_json()
  end

  def datatable_bulk_actions(datatable)
    bulk_actions_column = datatable.table_columns.find { |_, options| options[:bulk_actions_column] }.try(:second)
    return false unless bulk_actions_column

    {
      dropdownHtml: render(
        partial: bulk_actions_column[:dropdown_partial],
        locals: { datatable: datatable, dropdown_block: bulk_actions_column[:dropdown_block] }.merge(bulk_actions_column[:partial_locals])
      )
    }.to_json()
  end

  def datatable_header_filter(form, name, value, opts)
    return render(partial: opts[:header_partial], locals: {form: form, name: (opts[:label] || name), column: opts}) if opts[:header_partial].present?

    include_blank = opts[:filter].key?(:include_blank) ? opts[:filter][:include_blank] : (opts[:label] || name.titleize)
    pattern = opts[:filter].key?(:pattern) ? opts[:filter][:pattern] : nil
    placeholder = opts[:filter].key?(:placeholder) ? opts[:filter][:placeholder] : (opts[:label] || name.titleize)
    title = opts[:filter].key?(:title) ? opts[:filter][:title] : (opts[:label] || name.titleize)

    case opts[:filter][:as]
    when :string, :text, :number
      form.input name, label: false, required: false, value: value,
        as: :string,
        placeholder: placeholder,
        input_html: { name: nil, value: value, title: title, pattern: pattern, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} }
    when :obfuscated_id
      pattern ||= '[0-9]{3}-?[0-9]{4}-?[0-9]{3}'
      title = opts[:filter].key?(:title) ? opts[:filter][:title] : 'Expected format: XXX-XXXX-XXX'

      form.input name, label: false, required: false, value: value,
        as: :string,
        placeholder: placeholder,
        input_html: { name: nil, value: value, title: title, pattern: pattern, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} }
    when :date
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_date_picker) ? :effective_date_picker : :string),
        placeholder: placeholder,
        input_group: false,
        input_html: { name: nil, value: value, title: title, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { useStrict: true, keepInvalid: true }
    when :datetime
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_date_time_picker) ? :effective_date_time_picker : :string),
        placeholder: placeholder,
        input_group: false,
        input_html: { name: nil, value: value, title: title, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { useStrict: true, keepInvalid: true } # Keep invalid format like "2015-11" so we can still filter by year, month or day
    when :select, :boolean
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_select) ? :effective_select : :select),
        collection: opts[:filter][:collection],
        selected: opts[:filter][:selected],
        multiple: opts[:filter][:multiple] == true,
        include_blank: include_blank,
        input_html: { name: nil, value: value, title: title, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { placeholder: placeholder }
    when :grouped_select
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_select) ? :effective_select : :grouped_select),
        collection: opts[:filter][:collection],
        selected: opts[:filter][:selected],
        multiple: opts[:filter][:multiple] == true,
        include_blank: include_blank,
        grouped: true,
        polymorphic: opts[:filter][:polymorphic] == true,
        group_label_method: opts[:filter][:group_label_method] || :first,
        group_method: opts[:filter][:group_method] || :last,
        input_html: { name: nil, value: value, title: title, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index]} },
        input_js: { placeholder: placeholder }
    when :bulk_actions_column
      form.input name, label: false, required: false, value: nil,
        as: :boolean,
        input_html: { name: nil, value: nil, autocomplete: 'off', data: {'column-name' => opts[:name], 'column-index' => opts[:index], 'role' => 'bulk-actions-all'} }
    end
  end

end

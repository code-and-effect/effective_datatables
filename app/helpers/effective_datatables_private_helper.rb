# These aren't expected to be called by a developer.
# They are internal datatables methods, but you could still call them on the view.
module EffectiveDatatablesPrivateHelper

  # https://datatables.net/reference/option/columns
  def datatable_columns(datatable)
    form = nil
    simple_form_for(:datatable_filter, url: '#', html: {id: "#{datatable.to_param}-form"}) { |f| form = f }

    datatable.columns.map do |name, opts|
      {
        name: opts[:name],
        title: content_tag(:span, opts[:label], class: 'filter-label'),
        className: opts[:class],
        width: opts[:width],
        responsivePriority: opts[:responsive],
        sortable: (opts[:sortable] && !datatable.simple?),
        visible: datatable.state[:visible][name],
        filterHtml: (datatable_header_filter(form, name, datatable.state[:search][name], opts) unless datatable.simple?),
        filterSelectedValue: (datatable.state[:search][name] if datatable.state[:search].key?(name))
      }
    end.to_json
  end

  def datatable_bulk_actions(datatable)
    render(partial: '/effective/datatables/bulk_actions_dropdown') if datatable.bulk_actions.present?
  end

  def datatable_header_filter(form, name, value, opts)
    pattern = opts[:filter][:pattern]
    placeholder = opts[:filter][:placeholder] || ''
    title = opts[:filter][:title] || opts[:label] || opts[:name]
    wrapper_html = { class: 'datatable_filter' }

    input_html = {
      name: nil,
      value: value,
      title: title,
      pattern: pattern,
      autocomplete: 'off',
      data: {'column-name' => opts[:name], 'column-index' => opts[:index]}
    }.delete_if { |_, v| v.blank? }

    case opts[:filter][:as]
    when :string, :text, :number
      form.input name, label: false, required: false, value: value,
        as: :string,
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_html: input_html
    when :obfuscated_id
      input_html[:pattern] ||= '[0-9]{3}-?[0-9]{4}-?[0-9]{3}'
      input_html[:title] = 'Expected format: XXX-XXXX-XXX'

      form.input name, label: false, required: false, value: value,
        as: :string,
        placeholder: placeholder.presence || '###-####-###',
        wrapper_html: wrapper_html,
        input_html: input_html
    when :date
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_date_picker) ? :effective_date_picker : :string),
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_group: false,
        input_html: input_html,
        input_js: { useStrict: true, keepInvalid: true }
    when :datetime
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_date_time_picker) ? :effective_date_time_picker : :string),
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_group: false,
        input_html: input_html,
        input_js: { useStrict: true, keepInvalid: true } # Keep invalid format like "2015-11" so we can still filter by year, month or day
    when :select, :boolean
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_select) ? :effective_select : :select),
        collection: opts[:filter][:collection],
        selected: opts[:filter][:selected],
        multiple: opts[:filter][:multiple] == true,
        include_blank: include_blank,
        wrapper_html: wrapper_html,
        input_html: input_html,
        input_js: { placeholder: placeholder }
    when :grouped_select
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_select) ? :effective_select : :grouped_select),
        collection: opts[:filter][:collection],
        selected: opts[:filter][:selected],
        multiple: opts[:filter][:multiple] == true,
        grouped: true,
        polymorphic: opts[:filter][:polymorphic] == true,
        group_label_method: opts[:filter][:group_label_method] || :first,
        group_method: opts[:filter][:group_method] || :last,
        wrapper_html: wrapper_html,
        input_html: input_html,
        input_js: { placeholder: placeholder }
    when :bulk_actions
      input_html[:data]['role'] = 'bulk-actions-all'

      form.input name, label: false, required: false, value: nil,
        as: :boolean,
        input_html: input_html
    end
  end

end

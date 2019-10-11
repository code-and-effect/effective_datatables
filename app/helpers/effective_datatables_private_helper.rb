# These aren't expected to be called by a developer. They are internal methods.
# These aren't expected to be called by a developer. They are internal methods.
module EffectiveDatatablesPrivateHelper

  # https://datatables.net/reference/option/columns
  def datatable_columns(datatable)
    sortable = datatable.sortable?

    datatable.columns.map do |name, opts|
      {
        className: opts[:col_class],
        name: name,
        responsivePriority: opts[:responsive],
        search: datatable.state[:search][name],
        searchHtml: datatable_search_tag(datatable, name, opts),
        sortable: (opts[:sort] && sortable),
        title: datatable_label_tag(datatable, name, opts),
        visible: datatable.state[:visible][name]
      }
    end.to_json.html_safe
  end

  def datatable_bulk_actions(datatable)
    if datatable._bulk_actions.present?
      render(partial: '/effective/datatables/bulk_actions_dropdown', locals: { datatable: datatable }).gsub("'", '"').html_safe
    end
  end

  def datatable_display_order(datatable)
    (datatable.sortable? ? [datatable.order_index, datatable.order_direction] : false).to_json.html_safe
  end

  def datatable_reset(datatable)
    link_to(content_tag(:span, t('effective_datatables.reset')), '#', class: 'btn btn-link btn-sm buttons-reset-search')
  end

  def datatable_reorder(datatable)
    return unless datatable.reorder? && EffectiveDatatables.authorized?(self, :update, datatable.collection_class)
    link_to(content_tag(:span, t('effective_datatables.reorder')), '#', class: 'btn btn-link btn-sm buttons-reorder', disabled: true)
  end

  def datatable_new_resource_button(datatable, name, column)
    return unless column[:inline] && (column[:actions][:new] != false)

    action = { action: :new, class: ['btn', column[:btn_class].presence].compact.join(' '), 'data-remote': true }

    if column[:actions][:new].kind_of?(Hash) # This might be active_record_array_collection?
      action = action.merge(column[:actions][:new])

      effective_resource = (datatable.effective_resource || datatable.fallback_effective_resource)
      klass = (column[:actions][:new][:klass] || effective_resource&.klass || datatable.collection_class)
    elsif Array(datatable.effective_resource&.actions).include?(:new)
      effective_resource = datatable.effective_resource
      klass = effective_resource.klass
    else
      return
    end

    # Will only work if permitted
    render_resource_actions(klass, actions: { t('effective_datatables.new') => action }, effective_resource: effective_resource)
  end

  def datatable_label_tag(datatable, name, opts)
    case opts[:as]
    when :actions
      content_tag(:span, t('effective_datatables.actions'), style: 'display: none;')
    when :bulk_actions
      content_tag(:span, t('effective_datatables.bulk_actions'), style: 'display: none;')
    when :reorder
      content_tag(:span, t('effective_datatables.reorder'), style: 'display: none;')
    else
      content_tag(:span, opts[:label].presence)
    end
  end

  def datatable_search_tag(datatable, name, opts)
    return datatable_new_resource_button(datatable, name, opts) if name == :_actions

    return if opts[:search] == false

    # Build the search
    @_effective_datatables_form_builder ||  simple_form_for(:datatable_search, url: '#', html: {id: "#{datatable.to_param}-form"}) { |f| @_effective_datatables_form_builder = f }
    form = @_effective_datatables_form_builder

    include_blank = opts[:search].key?(:include_blank) ? opts[:search][:include_blank] : opts[:label]
    pattern = opts[:search][:pattern]
    placeholder = opts[:search][:placeholder] || ''
    title = opts[:search][:title] || opts[:label]
    wrapper_html = { class: 'datatable_search' }

    collection = opts[:search].delete(:collection)
    value = datatable.state[:search][name]
    input_html = {
      name: nil,
      value: value,
      title: title,
      pattern: pattern,
      autocomplete: opts[:search][:autocomplete] || SecureRandom.hex(32),
      class: opts[:search][:class] || 'form-control',
      data: {'column-name' => name, 'column-index' => opts[:index]}
    }.delete_if { |k, v| v.blank? && k != :name }

    case opts[:search][:as]
    when :string, :text, :number
      form.input name, label: false, required: false, value: value,
        as: :string,
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_html: input_html
    when :effective_obfuscation
      input_html[:pattern] ||= '[0-9]{3}-?[0-9]{4}-?[0-9]{3}'
      input_html[:title] = 'Expected format: XXX-XXXX-XXX'

      form.input name, label: false, required: false, value: value,
        as: :string,
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_html: input_html
    when :date, :datetime
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_date_picker) ? :effective_date_picker : :string),
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_group: false,
        input_html: input_html,
        date_linked: false,
        input_js: { useStrict: true, keepInvalid: true }
        # Keep invalid format like "2015-11" so we can still search by year, month or day
    when :time
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_time_picker) ? :effective_time_picker : :string),
        placeholder: placeholder,
        wrapper_html: wrapper_html,
        input_group: false,
        input_html: input_html,
        date_linked: false,
        input_js: { useStrict: false, keepInvalid: true }
    when :select, :boolean
      form.input name, label: false, required: false, value: value,
        as: (ActionView::Helpers::FormBuilder.instance_methods.include?(:effective_select) ? :effective_select : :select),
        collection: collection,
        selected: opts[:search][:value],
        multiple: opts[:search][:multiple],
        grouped: opts[:search][:grouped],
        polymorphic: opts[:search][:polymorphic],
        template: opts[:search][:template],
        include_blank: include_blank,
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

  def render_datatable_filters(datatable)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self
    return unless datatable._scopes.present? || datatable._filters.present?

    if datatable._filters_form_required?
      render partial: 'effective/datatables/filters', locals: { datatable: datatable }
    else
      render(partial: 'effective/datatables/filters', locals: { datatable: datatable }).gsub('<form', '<div').gsub('/form>', '/div>').html_safe
    end

  end

  def datatable_filter_tag(form, datatable, name, opts)
    as = opts[:as].to_s.chomp('_field').to_sym
    value = datatable.state[:filter][name]
    collection = opts[:collection]
    input_html = opts[:input_html] || {}

    form.input name,
      value: value,
      selected: value,
      as: as,
      collection: collection,
      label: opts[:label],
      required: input_html.delete(:required),
      multiple: input_html.delete(:multiple),
      include_blank: input_html.delete(:include_blank),
      group_method: input_html.delete(:group_method),
      group_label_method: input_html.delete(:group_label_method),
      value_method: input_html.delete(:value_method),
      label_method: input_html.delete(:label_method),
      input_html: (({name: ''} unless datatable._filters_form_required?) || {}).merge(input_html),
      input_js: ({ placeholder: ''} if as == :effective_select),
      wrapper_html: {class: 'form-group-sm'}
  end

  def datatable_scope_tag(form, datatable, opts = {})
    collection = datatable._scopes.map { |name, opts| [opts[:label], name] }
    value = datatable.state[:scope]

    form.input :scope, label: false, required: false, checked: value,
      as: (defined?(EffectiveFormInputs) ? :effective_radio_buttons : :radio_buttons),
      collection: collection,
      buttons: true,
      wrapper_html: {class: 'btn-group-sm'}
  end

  def render_datatable_charts(datatable)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self
    return unless datatable._charts.present?

    datatable._charts.map { |name, _| render_datatable_chart(datatable, name) }.join.html_safe
  end

  def render_datatable_chart(datatable, name)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self
    return unless datatable._charts[name].present?

    chart = datatable._charts[name]
    chart_data = datatable.to_json[:charts][name][:data]

    render partial: chart[:partial], locals: { datatable: datatable, chart: chart, chart_data: chart_data }
  end

end

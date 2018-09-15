# These aren't expected to be called by a developer. They are internal methods.
module EffectiveDatatablesPrivateHelper

  # https://datatables.net/reference/option/columns
  def datatable_columns(datatable)
    datatable.columns.map do |name, opts|
      {
        name: name,
        title: content_tag(:span, opts[:label].presence),
        className: opts[:col_class],
        responsivePriority: opts[:responsive],
        search: datatable.state[:search][name],
        searchHtml: datatable_search_tag(datatable, name, opts),
        sortable: (opts[:sort] && !datatable.simple?),
        visible: datatable.state[:visible][name],
      }
    end.to_json.html_safe
  end

  def datatable_bulk_actions(datatable)
    if datatable._bulk_actions.present?
      render(partial: '/effective/datatables/bulk_actions_dropdown', locals: { datatable: datatable }).gsub("'", '"').html_safe
    end
  end

  def datatable_reset(datatable)
    link_to(content_tag(:span, 'Reset'), '#', class: 'btn btn-link btn-sm buttons-reset-search')
  end

  def datatable_new_resource_button(datatable, name, column)
    if column[:inline] && column[:actions][:new] != false
      actions = {'New' => { action: :new, class: 'btn btn-outline-primary', 'data-remote': true } }
      render_resource_actions(datatable.resource.klass, actions: actions) # Will only work if permitted
    end
  end

  def datatable_search_tag(datatable, name, opts)
    return datatable_new_resource_button(datatable, name, opts) if name == :_actions

    return if opts[:search] == false

    # Build the search
    @_effective_datatables_form_builder || effective_form_with(scope: :datatable_search, url: '#') { |f| @_effective_datatables_form_builder = f }
    form = @_effective_datatables_form_builder

    collection = opts[:search].delete(:collection)
    value = datatable.state[:search][name]

    options = opts[:search].except(:fuzzy).merge!(
      name: nil,
      feedback: false,
      label: false,
      value: value,
      data: { 'column-name': name, 'column-index': opts[:index] }
    )

    case options.delete(:as)
    when :string, :text, :number
      form.text_field name, options
    when :date, :datetime
      form.date_field name, options.reverse_merge(
        date_linked: false, prepend: false, input_js: { useStrict: true, keepInvalid: true }
      )
    when :time
      form.time_field name, options.reverse_merge(
        date_linked: false, prepend: false, input_js: { useStrict: false, keepInvalid: true }
      )
    when :select, :boolean
      options[:input_js] = (options[:input_js] || {}).reverse_merge(placeholder: '')
      form.select name, collection, options
    when :bulk_actions
      options[:data]['role'] = 'bulk-actions'
      form.check_box name, options.merge(custom: false)
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
    placeholder = opts.delete(:label)

    collection = opts.delete(:collection)
    value = datatable.state[:filter][name]

    options = opts.except(:parse).merge(
      placeholder: placeholder,
      feedback: false,
      label: false,
      value: value,
      wrapper: { class: 'form-group col-auto'},
      autocomplete: 'off'
    )

    options[:name] = '' unless datatable._filters_form_required?

    case options.delete(:as)
    when :date
      form.date_field name, options
    when :datetime
      form.datetime_field name, options
    when :time
      form.time_field name, options
    when :select, :boolean
      options[:input_js] = (options[:input_js] || {}).reverse_merge(placeholder: placeholder)
      form.select name, collection, options
    else
      form.text_field name, options
    end
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

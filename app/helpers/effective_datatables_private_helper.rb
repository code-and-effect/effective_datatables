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
    ((datatable.sortable? && datatable.order_index) ? [datatable.order_index, datatable.order_direction] : false).to_json.html_safe
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
      form.check_box name, options.merge(label: '&nbsp;')
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

    options = {
      autocomplete: 'off',
      feedback: false,
      label: false,
      placeholder: (opts[:label] || name.to_s.titleize),
      value: value,
      wrapper: { class: 'form-group col-auto'}
    }.merge(opts.except(:as, :collection, :parse, :value))

    options[:name] = '' unless datatable._filters_form_required?

    if [:select, :radios, :checks].include?(as)
      options.delete(:name) unless as == :select
      form.public_send(as, name, collection, options) # select, radios, checks
    elsif as == :boolean
      collection ||= [true, false].map { |value| [t("effective_datatables.boolean_#{value}"), value] }
      form.public_send(:select, name, collection, options) # boolean
    elsif form.respond_to?(as)
      form.public_send(as, name, options) # check_box, text_area
    else
      form.public_send("#{as}_field", name, options) # text_field, number_field, all the rest.
    end

  end

  def datatable_scope_tag(form, datatable, opts = {})
    collection = datatable._scopes.map { |name, opts| [opts[:label], name] }
    value = datatable.state[:scope]

    options = {
      autocomplete: 'off',
      buttons: true,
      checked: value,
      feedback: false,
      label: false,
      required: false,
      wrapper: { class: 'form-group col-auto'}
    }.merge(opts.except(:checked, :value))

    form.radios :scope, collection, options
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

# frozen_string_literal: true

# These are expected to be called by a developer.  They are part of the datatables DSL.
module EffectiveDatatablesHelper
  def render_datatable(datatable, input_js: {}, buttons: true, charts: true, download: nil, entries: true, filters: true, inline: false, namespace: nil, nested: false, pagination: true, search: true, simple: false, short: false, sort: true)
    raise 'expected datatable to be present' unless datatable
    raise 'expected input_js to be a Hash' unless input_js.kind_of?(Hash)

    if download.nil?
      download = (buttons && EffectiveDatatables.download)
    end

    if simple
      buttons = charts = download = entries = filters = pagination = search = sort = false
    end

    if short
      entries = pagination = false
    end

    datatable.attributes[:inline] = true if inline
    datatable.attributes[:nested] = true if nested
    datatable.attributes[:sortable] = false unless sort
    datatable.attributes[:searchable] = false unless search
    datatable.attributes[:downloadable] = false unless download
    datatable.attributes[:namespace] = namespace if namespace

    datatable.view ||= self

    datatable.state[:length] = 9999999 if simple

    unless EffectiveDatatables.authorized?(controller, :index, datatable.collection_class)
      return content_tag(:p, "You are not authorized to view this datatable. (cannot :index, #{datatable.collection_class})")
    end

    charts = charts && datatable._charts.present?
    filters = filters && (datatable._scopes.present? || datatable._filters.present?)

    html_class = ['effective-datatable', datatable.html_class, ('hide-sort' unless sort), ('hide-search' unless search), ('hide-buttons' unless buttons)].compact.join(' ')

    if datatable.reorder? && !buttons
      buttons = true; input_js[:buttons] = false
    end

    # Build the datatables DOM option
    input_js[:dom] ||= [
      ("<'row'<'col-sm-12 dataTables_buttons'B>>" if buttons),
      "<'row'<'col-sm-12'tr>>",
      ("<'row'" if entries || pagination),
      ("<'col-sm-6 dataTables_entries'il>" if entries),
      ("<'col-sm-6'p>" if pagination),
      (">" if entries || pagination)
    ].compact.join

    effective_datatable_params = {
      id: datatable.to_param,
      class: html_class,
      data: {
        'all-label' => I18n.t('effective_datatables.all'),
        'attributes' => EffectiveDatatables.encrypt(datatable.attributes),
        'authenticity-token' => form_authenticity_token,
        'buttons-html' => datatable_buttons(datatable),
        'columns' => datatable_columns(datatable),
        'default-visibility' => datatable.default_visibility.to_json,
        'display-length' => datatable.display_length,
        'display-order' => datatable_display_order(datatable),
        'display-records' => datatable.to_json[:recordsFiltered],
        'display-start' => datatable.display_start,
        'inline' => inline.to_s,
        'language' => EffectiveDatatables.language(I18n.locale),
        'length-menu' => datatable_length_menu(datatable),
        'nested' => nested.to_s,
        'options' => input_js.to_json,
        'reorder' => datatable.reorder?.to_s,
        'reorder-index' => (datatable.columns[:_reorder][:index] if datatable.reorder?).to_s,
        'simple' => simple.to_s,
        'spinner' => icon('spinner'), # effective_bootstrap
        'source' => effective_datatables.datatable_path(datatable, {format: 'json'}),
        'total-records' => datatable.to_json[:recordsTotal]
      }
    }

    retval = if (charts || filters)
      output = ''.html_safe

      if charts
        datatable._charts.each { |name, _| output << render_datatable_chart(datatable, name) }
      end

      if filters
        output << render_datatable_filters(datatable)
      end

      output << render(partial: 'effective/datatables/datatable',
        locals: { datatable: datatable, effective_datatable_params: effective_datatable_params }
      )

      output
    else
      render(partial: 'effective/datatables/datatable',
        locals: { datatable: datatable, effective_datatable_params: effective_datatable_params }
      )
    end

    Rails.logger.info("  Rendered datatable #{datatable.class} #{datatable.source_location}")

    retval
  end

  def render_inline_datatable(datatable)
    render_datatable(datatable, inline: true)
  end

  def render_simple_datatable(datatable)
    render_datatable(datatable, simple: true)
  end

  def render_short_datatable(datatable)
    render_datatable(datatable, short: true)
  end

  def inline_datatable?
    params[:_datatable_id].present? && params[:_datatable_attributes].present?
  end

  def inline_datatable
    return nil unless inline_datatable?
    return @_inline_datatable if @_inline_datatable

    datatable = EffectiveDatatables.find(params[:_datatable_id], params[:_datatable_attributes])
    datatable.view = self

    EffectiveDatatables.authorize!(self, :index, datatable.collection_class)

    @_inline_datatable ||= datatable
  end

  def nested_datatable_link_to(title, path, options = {})
    options[:class] ||= 'btn btn-sm btn-link'
    options['data-remote'] = true
    options['data-nested'] = true

    link_to(title, path, options)
  end
end

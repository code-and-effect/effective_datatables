# These are expected to be called by a developer.  They are part of the datatables DSL.
module EffectiveDatatablesHelper

  def render_datatable(datatable, input_js: {}, charts: true, filters: true, simple: false)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self

    begin
      EffectiveDatatables.authorized?(controller, :index, datatable.collection_class) || raise(Effective::AccessDenied)
    rescue Effective::AccessDenied => e
      return content_tag(:p, "You are not authorized to view this datatable. (cannot :index, #{datatable.collection_class})")
    end

    charts = charts && datatable._charts.present?
    filters = filters && (datatable._scopes.present? || datatable._filters.present?)

    effective_datatable_params = {
      id: datatable.to_param,
      class: datatable.table_html_class,
      data: {
        'effective-form-inputs' => defined?(EffectiveFormInputs),
        'bulk-actions' => datatable_bulk_actions(datatable),
        'columns' => datatable_columns(datatable),
        'display-length' => datatable.display_length,
        'display-order' => [datatable.order_index, datatable.order_direction].to_json(),
        'display-records' => datatable.to_json[:recordsFiltered],
        'display-start' => datatable.display_start,
        'input-js-options' => (input_js || {}).to_json,
        'reset' => datatable_reset(datatable),
        'simple' => datatable.simple?.to_s,
        'source' => effective_datatables.datatable_path(datatable, {format: 'json'}),
        'total-records' => datatable.to_json[:recordsTotal]
      }
    }

    if (charts || filters) && !simple
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
      datatable.attributes[:simple] = true if simple

      render(partial: 'effective/datatables/datatable',
        locals: { datatable: datatable, effective_datatable_params: effective_datatable_params }
      )
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

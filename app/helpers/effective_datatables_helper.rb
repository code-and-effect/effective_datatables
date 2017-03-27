# These are expected to be called by a developer.  They are part of the datatables DSL.
module EffectiveDatatablesHelper

  def render_datatable(datatable, input_js_options = nil)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self

    begin
      EffectiveDatatables.authorized?(controller, :index, datatable.collection_class) || raise(Effective::AccessDenied)
    rescue Effective::AccessDenied => e
      return content_tag(:p, "You are not authorized to view this datatable. (cannot :index, #{datatable.collection_class})")
    end

    render partial: 'effective/datatables/datatable',
      locals: { datatable: datatable, input_js_options: input_js_options.try(:to_json) }
  end

  def render_simple_datatable(datatable, input_js_options = nil)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self
    datatable.attributes[:simple] = true

    begin
      EffectiveDatatables.authorized?(controller, :index, datatable.collection_class) || raise(Effective::AccessDenied)
    rescue Effective::AccessDenied => e
      return content_tag(:p, "You are not authorized to view this datatable. (cannot :index, #{datatable.collection_class})})")
    end

    render partial: 'effective/datatables/datatable',
      locals: {datatable: datatable, input_js_options: input_js_options.try(:to_json) }
  end

  def render_datatable_filters(datatable)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self
    return unless datatable._scopes.present? || datatable._filters.present?

    render partial: 'effective/datatables/filters', locals: { datatable: datatable }
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

    unless @effective_datatables_chart_javascript_rendered
      concat javascript_include_tag('https://www.google.com/jsapi')
      concat javascript_tag("if(google && google.visualization === undefined) { google.load('visualization', '1', {packages:#{EffectiveDatatables.google_chart_packages}}); }")

      @effective_datatables_chart_javascript_rendered = true
    end

    chart = datatable._charts[name]
    chart_data = datatable.to_json[:charts][name][:data]

    render partial: chart[:partial], locals: { datatable: datatable, chart: chart, chart_data: chart_data }
  end

end

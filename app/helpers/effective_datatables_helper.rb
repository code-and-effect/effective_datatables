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
    return unless datatable.scopes.present? || datatable.filters.present?

    render partial: 'effective/datatables/filters', locals: { datatable: datatable }
  end

  def render_datatable_charts(datatable)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self
    return unless datatable.charts.present?

    datatable.charts.map { |name, _| render_datatable_chart(datatable, name) }.join.html_safe
  end

  def render_datatable_chart(datatable, name)
    raise 'expected datatable to be present' unless datatable

    return unless datatable.charts.present?
    return unless datatable.charts[name].present?
    datatable.view ||= self

    unless @effective_datatables_chart_javascript_rendered
      concat javascript_include_tag('https://www.google.com/jsapi')
      concat javascript_tag("if(google && google.visualization === undefined) { google.load('visualization', '1', {packages:#{EffectiveDatatables.google_chart_packages}}); }")

      @effective_datatables_chart_javascript_rendered = true
    end

    options = datatable.charts[name]
    chart = datatable.to_json[:charts][name]

    render partial: (options[:partial] || 'effective/datatables/chart'),
      locals: { datatable: datatable, chart: chart }
  end

  ### Icon Helpers for actions_column or elsewhere
  def show_icon_to(path, options = {})
    glyphicon_to('eye-open', path, {title: 'Show'}.merge(options))
  end

  def edit_icon_to(path, options = {})
    glyphicon_to('edit', path, {title: 'Edit'}.merge(options))
  end

  def destroy_icon_to(path, options = {})
    defaults = {title: 'Destroy', data: {method: :delete, confirm: 'Delete this item?'}}
    glyphicon_to('trash', path, defaults.merge(options))
  end

  def archive_icon_to(path, options = {})
    defaults = {title: 'Archive', data: {method: :delete, confirm: 'Archive this item?'}}
    glyphicon_to('trash', path, defaults.merge(options))
  end

  def unarchive_icon_to(path, options = {})
    defaults = {title: 'Unarchive', data: {confirm: 'Unarchive this item?'}}
    glyphicon_to('retweet', path, defaults.merge(options))
  end

  def settings_icon_to(path, options = {})
    glyphicon_to('cog', path, {title: 'Settings'}.merge(options))
  end

  def ok_icon_to(path, options = {})
    glyphicon_to('ok', path, {title: 'OK'}.merge(options))
  end

  def approve_icon_to(path, options = {})
    glyphicon_to('ok', path, {title: 'Approve'}.merge(options))
  end

  def remove_icon_to(path, options = {})
    glyphicon_to('remove', path, {title: 'Remove'}.merge(options))
  end

  def glyphicon_to(icon, path, options = {})
    content_tag(:a, options.merge(href: path)) do
      if icon.start_with?('glyphicon-')
        content_tag(:span, '', class: "glyphicon #{icon}")
      else
        content_tag(:span, '', class: "glyphicon glyphicon-#{icon}")
      end
    end
  end
  alias_method :bootstrap_icon_to, :glyphicon_to
  alias_method :glyph_icon_to, :glyphicon_to

end

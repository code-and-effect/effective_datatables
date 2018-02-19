# These aren't expected to be called by a developer. They are internal methods.
module EffectiveDatatablesPrivateHelper

  # https://datatables.net/reference/option/columns
  def datatable_columns(datatable)
    form = nil
    effective_form_with(scope: :datatable_search, url: '#', html: { id: "#{datatable.to_param}-form" }) { |f| form = f }

    datatable.columns.map do |name, opts|
      {
        name: name,
        className: opts[:col_class],
        searchHtml: (datatable_search_html(form, name, datatable.state[:search][name], opts) unless datatable.simple?),
        responsivePriority: opts[:responsive],
        search: datatable.state[:search][name],
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
    link_to(content_tag(:span, 'Reset'), '#', class: 'btn btn-light buttons-reset-search')
  end

  def datatable_search_html(form, name, value, opts)
    collection = opts[:search].delete(:collection)

    options = opts[:search]
      .except(:fuzzy)
      .reverse_merge(label: (opts[:label].presence || false), value: value)
      .merge(name: nil, feedback: false, data: {'column-name': name, 'column-index': opts[:index]})

    case options.delete(:as)
    when :string, :text, :number
      form.text_field name, options
    when :date, :datetime
      form.date_field name, options.merge(
        date_linked: false, prepend: false, input_js: { useStrict: true, keepInvalid: true }
      )
    when :time
      form.time_field name, options.merge(
        date_linked: false, prepend: false, input_js: { useStrict: false, keepInvalid: true }
      )
    when :select, :boolean
      form.select name, collection, options
    when :bulk_actions
      options[:data]['role'] = 'bulk-actions-all'
      form.check_box name, options.merge(custom: false)
    end

  end

end

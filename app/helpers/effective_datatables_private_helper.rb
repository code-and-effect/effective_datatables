# These aren't expected to be called by a developer. They are internal methods.
module EffectiveDatatablesPrivateHelper

  # https://datatables.net/reference/option/columns
  def datatable_columns(datatable)
    datatable.columns.map do |name, opts|
      {
        name: name,
        className: opts[:col_class],
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

  def datatable_header_tag(datatable, name, opts)
    # Build the label
    label = opts[:label].present? ? content_tag(:span, opts[:label]) : ''.html_safe
    return label if opts[:search] == false

    # Build the search
    @_effective_datatables_form_builder || effective_form_with(scope: :datatable_search) { |f| @_effective_datatables_form_builder = f }
    form = @_effective_datatables_form_builder

    collection = opts[:search].delete(:collection)

    options = opts[:search].except(:fuzzy).merge!(
      name: nil,
      feedback: false,
      label: false,
      value: datatable.state[:search][name],
      data: { 'column-name': name, 'column-index': opts[:index] }
    )

    label + case options.delete(:as)
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
      form.select name, collection, options
    when :bulk_actions
      options[:data]['role'] = 'bulk-actions-all'
      form.check_box name, options.merge(custom: false)
    end
  end

  def datatable_filter_tag(form, datatable, name, opts)
    options = opts.except(:parse).merge(value: datatable.state[:filter][name])
    options[name] = '' unless datatable._filters_form_required?

    collection = options.delete(:collection)

    case options.delete(:as)
    when :date, :datetime
      form.date_field name, options
    when :time
      form.time_field name, options
    when :select, :boolean
      form.select name, collection, options
    else
      form.text_field name, options
    end
  end

end

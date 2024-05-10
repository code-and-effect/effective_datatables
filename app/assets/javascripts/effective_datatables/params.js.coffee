getFilterParams = ->
  table_id = @table().node().id
  $form = $(".effective-datatables-filters[aria-controls='#{table_id}']").first()

  # Parse Filter & Scope Params
  params = {}

  if $form.length > 0
    params['scope'] = $form.find("input[name='filters[scope]']:checked").val() || ''
    params['filter'] = {}

    $form.find("select,textarea,input:enabled:not([type=submit])").each ->
      $input = $(this)

      if ['utf8', 'authenticity_token', 'filters[scope]'].includes($input.attr('name'))
        # Skipped
      else if $input.attr('type') == 'radio'
        name = $input.attr('name')
        filter_name = name.replace('filters[', '').substring(0, name.length-9)

        params['filter'][filter_name] = $form.find("input[name='#{name}']:checked").val()

      else if $input.attr('id')
        filter_name = $input.attr('id').replace('filters_', '')
        params['filter'][filter_name] = $input.val()

  params

$.fn.DataTable.Api.register('getFilterParams()', getFilterParams)

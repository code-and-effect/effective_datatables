#### Checkbox toggling and Bulk Actions dropdown disabling

$(document).on 'change', ".dataTables_wrapper input[data-role='bulk-action']", (event) ->
  $wrapper = $(event.currentTarget).closest('.dataTables_wrapper')

  $wrapper.find("input[data-role='bulk-actions']").prop('checked', false)
  toggleBulkActionsDropdown($wrapper)

$(document).on 'change', ".dataTables_wrapper input[data-role='bulk-actions']", (event) ->
  $wrapper = $(event.currentTarget).closest('.dataTables_wrapper')
  $resources = $wrapper.find("input[data-role='bulk-action']")

  if $(event.currentTarget).is(':checked')
    $resources.prop('checked', true)
  else
    $resources.prop('checked', false)

  toggleBulkActionsDropdown($wrapper)

toggleBulkActionsDropdown = ($wrapper) ->
  $bulkActions = $wrapper.children().first().find('.buttons-bulk-actions').children('button')

  if $wrapper.find("input[data-role='bulk-action']:checked").length > 0
    $bulkActions.removeAttr('disabled')
  else
    $bulkActions.attr('disabled', 'disabled')

#### Bulk Action link behaviour
$(document).on 'click', '.buttons-bulk-actions a', (event) ->
  event.preventDefault() # prevent the click

  $bulkAction = $(event.currentTarget)  # This is a regular <a href=...> tag
  $wrapper = $bulkAction.closest('.dataTables_wrapper')
  $table = $wrapper.find('table.dataTable').first()
  $processing = $table.siblings('.dataTables_processing').first()
  $selected = $table.find("input[data-role='bulk-action']:checked")

  url = $bulkAction.attr('href')
  title = $bulkAction.text()
  token = $bulkAction.parent('li').data('authenticity-token')
  values = $.map($selected, (input) -> input.getAttribute('value'))
  method = $bulkAction.data('ajax-method')

  return unless url && values

  if method == 'GET'
    if url.includes('?')
      window.location.assign(url + '&' + $.param({ids: values}))
    else
      window.location.assign(url + '?' + $.param({ids: values}))

    return

  # Disable the Bulk Actions dropdown, so only one can be run at a time
  $bulkAction.closest('button').attr('disabled', 'disabled')

  # Show Processing...
  $processing.show().data('bulk-actions-processing', true)
  $table.dataTable().data('bulk-actions-restore-selected-values', values)

  if token # This is a file download
    $.fileDownload(url,
      httpMethod: 'POST',
      data: { ids: values, authenticity_token: token }
      successCallback: ->
        success = "Successfully completed #{title} bulk action"
        $processing.html(success)
        $table.DataTable().draw()
      failCallback: ->
        error = "An error occured while attempting #{title} bulk action"
        $processing.html(error)
        alert(error)
        $table.DataTable().draw()
    )
  else # Normal AJAX post
    $table.dataTable().data('bulk-actions-restore-selected-values', values)
    $table.one 'draw.dt', (e, settings) -> settings.blockProcessing = true

    $.ajax(
      method: method,
      url: url,
      data: { ids: values }
    ).done((response) ->
      success = response['message'] || "Successfully completed #{title} bulk action"
      $table.one 'draw.dt', (e) -> $(e.target).DataTable().flash(success)
    ).fail((response) ->
      error = response['message'] || "An error occured while attempting #{title} bulk action: #{response.statusText}"
      $table.one 'draw.dt', (e) -> $(e.target).DataTable().flash(error)
    ).always((response) ->
      $table.DataTable().draw()
    )

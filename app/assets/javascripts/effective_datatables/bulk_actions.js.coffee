#### Checkbox toggling and Bulk Actions dropdown disabling

$(document).on 'change', "input[data-role='bulk-actions-resource']", (event) ->
  $wrapper = $(event.currentTarget).closest('.dataTables_wrapper')

  $wrapper.find("input[data-role='bulk-actions-all']").prop('checked', false)
  toggleClosestBulkActionsButton($wrapper)

$(document).on 'change', "input[data-role='bulk-actions-all']", (event) ->
  $wrapper = $(event.currentTarget).closest('.dataTables_wrapper')
  $resources = $wrapper.find("input[data-role='bulk-actions-resource']")

  if $(event.currentTarget).is(':checked')
    $resources.prop('checked', true)
  else
    $resources.prop('checked', false)

  toggleClosestBulkActionsButton($wrapper)

toggleClosestBulkActionsButton = ($wrapper) ->
  $bulkActions = $wrapper.children().first().find('.buttons-bulk-actions').children('button')

  if $wrapper.find("input[data-role='bulk-actions-resource']:checked").length > 0
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
  $selected = $table.find("input[data-role='bulk-actions-resource']:checked")

  url = $bulkAction.attr('href')
  title = $bulkAction.text()
  values = $.map($selected, (input) -> input.getAttribute('value'))
  token = $bulkAction.parent('li').data('authenticity-token')

  return unless url && values

  # Disable the Bulk Actions dropdown, so only one can be run at a time
  $bulkAction.closest('button').attr('disabled', 'disabled')

  # Show Processing...
  $processing.show().data('bulk-actions-processing', true)

  if token # This is a file download
    $.fileDownload(url,
      httpMethod: 'POST',
      data: { ids: values, authenticity_token: token }
      successCallback: ->
        success = "Successfully completed #{title} bulk action"
        $processing.html(success)
        $table.dataTable().data('bulk-actions-restore-selected-values', values)
        $table.DataTable().draw()
      failCallback: ->
        error = "An error occured while attempting #{title} bulk action"
        $processing.html(error)
        alert(error)
        $table.dataTable().data('bulk-actions-restore-selected-values', values)
        $table.DataTable().draw()
    )
  else # Normal AJAX post
    $.post(
      url, { ids: values }
    ).done((response) ->
      success = response['message'] || "Successfully completed #{title} bulk action"
      $processing.html(success)
    ).fail((response) ->
      error = response['message'] || "An error occured while attempting #{title} bulk action: #{response.statusText}"
      $processing.html(error)
      alert(error)
    ).always((response) ->
      $table.dataTable().data('bulk-actions-restore-selected-values', values)
      $table.DataTable().draw()
    )

# We borrow the Processing div for our bulk action success/error messages
# This makes sure that the message is displayed for 1500ms
$(document).on 'processing.dt', (event, settings, visible) ->
  return if settings.bDestroying

  $processing = $(event.target).siblings('.dataTables_processing').first()
  return unless $processing.data('bulk-actions-processing')

  timeout = $processing.show().data('timeout')
  clearTimeout(timeout) if timeout
  $processing.data('timeout', setTimeout( =>
      $processing.html('Processing...').hide()
      $processing.data('bulk-actions-processing', null)
    , 1500)
  )

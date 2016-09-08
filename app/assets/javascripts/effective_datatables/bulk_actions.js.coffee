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
  $selected = $table.find("input[data-role='bulk-actions-resource']:checked")

  url = $bulkAction.attr('href')
  title = $bulkAction.text()
  values = $.map($selected, (input) -> input.getAttribute('value'))

  return unless url && values

  # Show Processing... and disable the Bulk Actions dropdown
  $table.siblings('.dataTables_processing').show()
  $wrapper.children().first().find('.buttons-bulk-actions').children('button').attr('disabled', 'disabled')

  $.post(
    url, { ids: values }
  ).done((response) ->
    success = response['message'] || "Successfully completed #{title} bulk action"
    $table.siblings('.dataTables_processing').html(success)
  ).fail((response) ->
    error = response['message'] || "An error occured while attempting #{title} bulk action: #{response.statusText}"
    $table.siblings('.dataTables_processing').html(error)
    alert(error)
  ).always((response) ->
    $table.dataTable().data('bulk-actions-restore-selected-values', values)
    $table.DataTable().draw()
  )

$(document).on 'change', "input[data-role='bulk-actions-resource']", (event) ->
  $("input[data-role='bulk-actions-all']").prop('checked', false)
  toggleClosestBulkActionsButton($(event.currentTarget))

$(document).on 'change', "input[data-role='bulk-actions-all']", (event) ->
  $checkAll = $(event.currentTarget)
  $resources = $("input[data-role='bulk-actions-resource']")

  if $checkAll.is(':checked')
    $resources.prop('checked', true)
  else
    $resources.prop('checked', false)

  toggleClosestBulkActionsButton($checkAll)

toggleClosestBulkActionsButton = (element) ->
  $table = element.closest('.dataTables_wrapper')
  $bulkActions = $table.children().first().find('.buttons-bulk-actions').children('button')

  if $table.find("input[data-role='bulk-actions-resource']:checked").length > 0
    $bulkActions.removeAttr('disabled')
  else
    $bulkActions.attr('disabled', 'disabled')

reorder = (event, diff, edit) ->
  change = diff.find (obj) -> obj.node == edit.triggerRow.node()
  return unless change?

  oldNode = $("<div>#{change.oldData}</div>").find('input[data-reorder-resource]')
  newNode = $("<div>#{change.newData}</div>").find('input[data-reorder-resource]')
  return unless oldNode? && newNode?

  url = @context[0].ajax.url.replace('.json', '/reorder.json')
  data = {'reorder[id]': oldNode.data('reorder-resource'), 'reorder[old]': oldNode.val(), 'reorder[new]': newNode.val()}

  @context[0].rowreorder.c.enable = false

  $.ajax(
    method: 'post',
    url: url,
    data: data,
    async: false
  ).fail((response, text, status) =>
    $(event.target).closest('table').DataTable().flash(status, 'danger')
  ).always((response) =>
    @context[0].rowreorder.c.enable = true
  )

$.fn.DataTable.Api.register('reorder()', reorder);

$(document).on 'click', '.dataTables_wrapper a.buttons-reorder', (event) ->
  event.preventDefault() # prevent the click

  $link = $(event.currentTarget)
  $table = $link.closest('.dataTables_wrapper').find('table.dataTable').first()

  column = $table.DataTable().column('.col-_reorder')
  return unless column.length > 0

  if column.visible()
    $table.removeClass('reordering')
  else
    $table.addClass('reordering')

  column.visible(!column.visible())


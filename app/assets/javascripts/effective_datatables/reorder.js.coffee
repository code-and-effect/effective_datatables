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
    $(event.target).closest('table').DataTable().flash(status)
  ).always((response) =>
    @context[0].rowreorder.c.enable = true
  )

$.fn.DataTable.Api.register('reorder()', reorder);

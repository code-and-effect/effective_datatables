reorder = (event, diff, edit) ->
  return if diff.length == 0

  console.log "Reorder!!"

  url = @context[0].ajax.url.replace('.json', '/reorder.json')


  console.log diff
  console.log edit

  $.ajax(
    method: 'post',
    url: url,
    data: { ids: [1, 2, 3] }
  ).done((response) ->
    console.log 'DONE'
  ).fail((response) ->
    console.log "FAIL"
  )

  # if diff.length == 0
  #   event.preventDefault()
  #   event.stopPropagation()

  # console.log 'reorder kkk'
  # console.log @context[0]
  # console.log @context[0].ajax
  # console.log @context[0].ajax['url']
  # console.log @context[0].ajax.url

  # console.log @table
  # console.log @table.node()

  # console.log event
  # console.log diff
  # console.log edit


$.fn.DataTable.Api.register('reorder()', reorder);

# Redraw the table, and initialize any filter form inputs after the last column made visible
$(document).on 'column-visibility.dt', (event, settings, index, state) ->
  return if settings.bDestroying

  $table = $(event.target)

  timeout = $table.data('timeout')
  clearTimeout(timeout) if timeout
  $table.data('timeout', setTimeout( =>
      $table.DataTable().draw()
      $.event.trigger('page:change')
    , 700)
  )

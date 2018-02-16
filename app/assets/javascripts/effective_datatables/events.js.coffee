# Redraw the table, and initialize any filter form inputs after the last column made visible
$(document).on 'column-visibility.dt', (event, settings, index, state) ->
  return if settings.bDestroying

  $table = $(event.target)

  timeout = $table.data('timeout')
  clearTimeout(timeout) if timeout
  $table.data('timeout', setTimeout( =>
      $table.DataTable().draw()
    , 700)
  )
  true

# Remove empty label (bulk actions) from ColVis dropdown
$(document).on 'click', 'a.buttons-colvis:not(.initialized)', (event) ->
  $colvis = $('.dt-button-collection')
  return if $colvis.length == 0

  $colvis.find('a > span:empty').each -> $(this).parent().remove()
  $colvis.find('a.buttons-colvisGroup').first().before("<div class='dropdown-divider'></div>")
  $(event.currentTarget).addClass('initialized')

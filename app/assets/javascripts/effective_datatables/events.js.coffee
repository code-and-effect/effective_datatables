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

# Remove empty label (bulk actions) from ColVis dropdown
$(document).on 'click.dtb-collection', (event) ->
  $colvis = $('.dt-button-collection:not(.initialized)')
  return if $colvis.length == 0

  $colvis.addClass('initialized').find('li > a:empty').each -> $(this).parent().remove()

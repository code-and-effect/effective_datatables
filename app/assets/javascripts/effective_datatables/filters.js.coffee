$(document).on 'click', 'a[data-reset-datatable-filters]', (event) ->
  event.preventDefault()
  $(event.currentTarget).closest('form').trigger('reset')

$(document).on 'click', 'a[data-apply-datatable-filters]', (event) ->
  event.preventDefault()
  $table = $('#' + $(event.currentTarget).closest('form').attr('aria-controls'))
  $table.DataTable().draw()


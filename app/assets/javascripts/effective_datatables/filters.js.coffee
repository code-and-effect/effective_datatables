$(document).on 'click', 'a[data-apply-datatable-filters]', (event) ->
  event.preventDefault()
  $form = $(event.currentTarget).closest('.effective-datatable-filters')
  $table = $('#' + $form.attr('aria-controls'))
  $table.DataTable().draw()


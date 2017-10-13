$(document).on 'click', 'a[data-apply-effective-datatables-filters]', (event) ->
  event.preventDefault()
  $form = $(event.currentTarget).closest('.effective-datatables-filters')
  $table = $('#' + $form.attr('aria-controls'))
  $table.DataTable().draw()


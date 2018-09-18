# Don't scope by .datatables_wrapper here, because it's out of the wrapper!
$(document).on 'click', 'a[data-apply-effective-datatables-filters]', (event) ->
  event.preventDefault()
  $form = $(event.currentTarget).closest('.effective-datatables-filters')
  $table = $('#' + $form.attr('aria-controls'))
  $table.DataTable().draw()


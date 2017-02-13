$(document).on 'click', 'a[data-reset-datatable-filters]', (event) ->
  event.preventDefault()
  $(event.currentTarget).closest('form').trigger('reset')

$(document).on 'click', 'a[data-apply-datatable-filters]', (event) ->
  event.preventDefault()
  $form = $(event.currentTarget).closest('form')

  if $form.find('input[required],select[required]').val() == ''
    alert('Please fill out all required fields')
    return

  $table = $('#' + $form.attr('aria-controls'))
  $table.DataTable().draw()


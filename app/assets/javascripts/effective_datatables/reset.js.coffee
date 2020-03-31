$(document).on 'click', '.dataTables_wrapper a.buttons-reset-search', (event) ->
  event.preventDefault() # prevent the click

  # Reset the HTML
  $table = $(event.currentTarget).closest('.dataTables_wrapper').find('table.dataTable').first()
  $thead = $table.children('thead').first()

  # Reset all inputs
  $thead.find('select').val('').trigger('change.select2')

  $inputs = $thead.find('input')
  $inputs.val('').removeAttr('checked').removeAttr('selected')

  # Reset delayedChange
  $.each $inputs, (input) =>
    $input = $(input)
    if ($input.delayedChange.oldVal)
      $input.delayedChange.oldVal = undefined

  # Reset the datatable
  datatable = $table.DataTable()

  # Reset search
  datatable.search('').columns().search('')

  # Reset to default visibility
  $.each $table.data('default-visibility'), (index, visible) =>
    datatable.column(index).visible(visible, false)

  # Don't pass up the click
  false


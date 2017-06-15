$(document).on 'click', 'a.buttons-reset-search', (event) ->
  event.preventDefault() # prevent the click

  $table = $(event.currentTarget).closest('.dataTables_wrapper').find('table.dataTable').first()
  $thead = $table.children('thead').first()

  $thead.find('input').val('').removeAttr('checked').removeAttr('selected')
  $thead.find('select').val('').trigger('change.select2')

  $table.DataTable().search('').columns().search('').draw()


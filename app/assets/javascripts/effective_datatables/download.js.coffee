$(document).on 'click', '.dataTables_wrapper a.buttons-download', (event) ->
  $button = $(event.currentTarget)
  $table = $('#' + $button.attr('aria-controls'))

  url = $table.data('source').replace('.json', '/download.csv')
  attributes = 'attributes=' + encodeURIComponent($table.data('attributes'))

  $form = $(".effective-datatables-filters[aria-controls='#{$table.attr('id')}']").first()
  filters = $form.find("input,select,option,textarea").serialize()

  console.log("FILTERS IS: #{filters}")

  $button.attr('href', url + '?' + attributes + '&' + filters)

  setTimeout (=> $button.attr('href', 'download.csv')), 0

$(document).on 'click', '.dataTables_wrapper a.buttons-download', (event) ->
  $button = $(event.currentTarget)
  $table = $('#' + $button.attr('aria-controls'))

  url = $table.data('source').replace('.json', '/download.csv')
  attributes = 'attributes=' + encodeURIComponent($table.data('attributes'))

  $(event.currentTarget).attr('href', url + '?' + attributes)

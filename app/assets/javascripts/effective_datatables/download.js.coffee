$(document).on 'click', '.dataTables_wrapper a.buttons-download', (event) ->
  $button = $(event.currentTarget)
  $table = $('#' + $button.attr('aria-controls'))

  url = $table.data('source').replace('.json', '/download.csv')
  attributes = 'attributes=' + encodeURIComponent($table.data('attributes'))

  # Parse filters and flatten
  filterParams = $table.DataTable().getFilterParams() || {}
  params = filterParams['filter'] || {}
  params['scope'] = filterParams['scope'] if filterParams['scope']

  filters = '&' + $.param(params)

  $button.attr('href', url + '?' + attributes + filters)

  setTimeout (=> $button.attr('href', 'download.csv')), 0

$(document).on 'shown.bs.tab', "a[data-toggle='tab']", (event) ->
  $($(event.target).attr('href')).find('table.dataTable').each ->
    $(this).DataTable().columns.adjust().responsive.recalc()


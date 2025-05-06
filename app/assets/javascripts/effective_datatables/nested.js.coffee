# Make all links for nested datatables open in new tabs
$(document).on 'click', '.dataTables_wrapper_nested a', (event) ->
  $link = $(event.currentTarget)
  $link.attr('target', '_blank')
  true

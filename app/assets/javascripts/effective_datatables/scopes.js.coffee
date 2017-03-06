$(document).on 'click', 'a[data-clear-form]', (event) ->
  event.preventDefault()
  $(event.currentTarget).closest('form').trigger('clear')

$(document).on 'clear', '.effective-datatable-scopes form', (event) ->
  $(this).find('.radio.active').removeClass('active');
  $(this).find(':radio').prop('checked', false);
  $(this).submit()
$(document).on 'click', 'a[data-reset-form]', (event) ->
  event.preventDefault()
  $(event.currentTarget).closest('form').trigger('reset')

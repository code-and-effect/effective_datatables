$(document).on 'click', 'a.buttons-reset-cookie', (event) ->
  event.preventDefault()

  $obj = $(event.currentTarget)
  $obj.find('span').text('Resetting...')
  document.cookie = "#{$obj.data('cookie-name')}=; expires=Thu, 01-Jan-70 00:00:01 GMT; path=/"
  location.reload()

flash = (message, status = '') ->
  @context[0].oFeatures.bProcessing = false

  message ||= 'Processing...'

  if status == 'danger'
    message = 'Error: ' + message

  $processing = $(@table().node()).siblings('.dataTables_processing')

  if status.length > 0
    $processing.addClass("alert-#{status}")

  $processing.html(message).show()

  timeout = $processing.data('timeout')
  clearTimeout(timeout) if timeout

  delay = (if status == 'danger' then 4000 else 1000)

  $processing.html(message).data('timeout', setTimeout( =>
      $processing.html('Processing...')
      $processing.removeClass('alert-success alert-info alert-warning alert-danger alert-error')
      $processing.hide()
      @context[0].oFeatures.bProcessing = true
    , delay)
  )

  return @

$.fn.DataTable.Api.register('flash()', flash);

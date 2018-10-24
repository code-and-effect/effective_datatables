flash = (message) ->
  @context[0].oFeatures.bProcessing = false

  message ||= 'Processing...'

  $processing = $(@table().node()).siblings('.dataTables_processing')
  $processing.html(message).show()

  timeout = $processing.data('timeout')
  clearTimeout(timeout) if timeout

  $processing.html(message).data('timeout', setTimeout( =>
      $processing.html('Processing...').hide()
      @context[0].oFeatures.bProcessing = true
    , 1500)
  )

  return @

$.fn.DataTable.Api.register('flash()', flash);

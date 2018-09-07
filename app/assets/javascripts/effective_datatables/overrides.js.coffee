$.extend(true, $.fn.dataTable.Buttons.defaults, {
  dom: {
    button: {
      className: 'btn btn-link btn-sm'
    }
  }
});

# DataTable is the API
# dataTable is the object fnStuff

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

# @context[0]
$.fn.DataTable.Api.register('flash()', flash);

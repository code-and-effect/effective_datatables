$.extend(true, $.fn.dataTable.Buttons.defaults, {
  dom: {
    button: {
      className: 'btn btn-link btn-sm'
    }
  }
});

# $(@table().node)

# DataTable is the API
# dataTable is the object fnStuff

flash = (message) ->
  $processing = $(@table().node()).siblings('.dataTables_processing')

  timeout = $processing.data('timeout')
  clearTimeout(timeout) if timeout

  $processing.html(message).data('timeout', setTimeout( =>
      $processing.html('Processing...').hide()
      @context[0].blockProcessing = false
    , 1500)
  )

  $processing.html(message).show()
  @context[0].oInstance._fnProcessingDisplay(@context[0], true)
  @context[0].blockProcessing = true

# @context[0]
$.fn.DataTable.Api.register('flash()', flash);





  # timeout = $processing.show().data('timeout')
  # clearTimeout(timeout) if timeout
  # $processing.data('timeout', setTimeout( =>
  #     $processing.html('Processing...').hide()
  #     $processing.data('bulk-actions-processing', null)
  #   , 1500)
  # )

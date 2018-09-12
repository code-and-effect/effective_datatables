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

  return @

turboDestroy = ->
  @iterator('table', (settings) ->
    $(window).off('.DT-' + settings.sInstance)

    index = $.inArray(settings, $.fn.DataTable.settings)
    $.fn.DataTable.settings.splice(index, 1) if index > -1
  )

$.fn.DataTable.Api.register('flash()', flash);
$.fn.DataTable.Api.register('turboDestroy()', turboDestroy);

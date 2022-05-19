#### Checkbox toggling and Bulk Actions dropdown disabling

$(document).on 'change', ".dataTables_wrapper input[data-role='bulk-action']", (event) ->
  $wrapper = $(event.currentTarget).closest('.dataTables_wrapper')

  $wrapper.find("input[data-role='bulk-actions']").prop('checked', false)
  toggleDropdown($wrapper)

$(document).on 'mousedown', ".dataTables_wrapper .buttons-bulk-actions [data-confirm]", (event) ->
  $obj = $(event.currentTarget)
  return if $obj.data('confirmed')

  $wrapper = $obj.closest('.dataTables_wrapper')
  selected = $wrapper.find("input[data-role='bulk-action']:checked").length

  unless $obj.data('bulk-action-original-confirm')
    $obj.data('bulk-action-original-confirm', $obj.data('confirm'))

  newConfirm = $obj.data('bulk-action-original-confirm') + "\n\n"

  if selected == 1
    newConfirm += "This action will affect #{selected} item."
  else
    newConfirm += "This action will affect #{selected} items."

  $obj.attr('data-confirm', newConfirm)

$(document).on 'change', ".dataTables_wrapper input[data-role='bulk-actions']", (event) ->
  $wrapper = $(event.currentTarget).closest('.dataTables_wrapper')
  $resources = $wrapper.find("input[data-role='bulk-action']")

  if $(event.currentTarget).is(':checked')
    $resources.prop('checked', true)
  else
    $resources.prop('checked', false)

  toggleDropdown($wrapper)

toggleDropdown = ($wrapper) ->
  $bulkActions = $wrapper.children().first().find('.buttons-bulk-actions').children('button')
  selected = $wrapper.find("input[data-role='bulk-action']:checked").length

  if selected > 0
    $bulkActions.removeAttr('disabled').text("Bulk Actions (#{selected} items)")
  else
    $bulkActions.attr('disabled', 'disabled').text('Bulk Actions')

restoreSelected = ($table, selected) ->
  $bulkActions = $table.closest('.dataTables_wrapper').children().first().find('.buttons-bulk-actions').children('button')
  present = false

  if selected && selected.length > 0
    $table.find("input[data-role='bulk-action']").each (_, input) ->
      $input = $(input)

      if selected.indexOf($input.val()) > -1
        $input.prop('checked', true)
        present = true
      else
        $input.prop('checked', false)

  if present then $bulkActions.removeAttr('disabled') else $bulkActions.attr('disabled', 'disabled')

# rails_ujs data-confirm requires special attention
# https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/rails-ujs/features/confirm.coffee
$(document).on 'confirm:complete', '.dataTables_wrapper .buttons-bulk-actions a', (event) ->
  if event.originalEvent.detail && event.originalEvent.detail[0] == true
    doBulkActionPost(event)
    (window.Rails || $.rails).stopEverything(event)
    return false

$(document).on 'click', '.dataTables_wrapper .buttons-bulk-actions a', (event) ->
  unless $(event.currentTarget).data('confirm')
    doBulkActionPost(event)
    event.preventDefault()

doBulkActionPost = (event) ->
  $bulkAction = $(event.currentTarget)  # This is the regular <a href=...> tag maybe with data-confirm

  document.cookie = 'ids=; expires=Thu, 01 Jan 1970 00:00:00 GMT'
  localStorage.removeItem('ids')

  $wrapper = $bulkAction.closest('.dataTables_wrapper')
  $table = $wrapper.find('table.dataTable').first()
  $processing = $table.siblings('.dataTables_processing').first()
  $selected = $table.find("input[data-role='bulk-action']:checked")

  url = $bulkAction.attr('href')
  title = $bulkAction.text()
  download = $bulkAction.data('bulk-download')
  payload_mode = $bulkAction.data('payload-mode')
  token = $table.data('authenticity-token')
  values = $.map($selected, (input) -> input.getAttribute('value'))
  method = $bulkAction.data('ajax-method')

  return unless url && values

  if method == 'GET'
    if payload_mode == 'cookie'
      document.cookie = "ids=#{values}";
      window.location.assign(url)
    else if payload_mode == 'local-storage'
      localStorage.setItem('ids', values);
      window.location.assign(url)
    else
      if url.includes('?')
        window.location.assign(url + '&' + $.param({ids: values}))
      else
        window.location.assign(url + '?' + $.param({ids: values}))

    return

  # Disable the Bulk Actions dropdown, so only one can be run at a time
  $bulkAction.closest('button').attr('disabled', 'disabled')

  $table.dataTable().data('bulk-actions-restore-selected-values', values)

  if download # This is a file download
    $.fileDownload(url,
      httpMethod: 'POST',
      data: { ids: values, authenticity_token: token }
      successCallback: ->
        success = "Successfully completed #{title} bulk action"
        $table.one 'draw.dt', (e) -> $(e.target).DataTable().flash(success, 'success')
        $table.DataTable().draw()
      failCallback: ->
        error = "An error occured while attempting #{title} bulk action"
        $table.one 'draw.dt', (e) -> $(e.target).DataTable().flash(error, 'danger')
        $table.DataTable().draw()
    )
  else # Normal AJAX post
    $table.dataTable().data('bulk-actions-restore-selected-values', values)

    $.ajax(
      method: method,
      url: url,
      data: { ids: values, authenticity_token: token }
    ).done((response) ->
      success = response['message'] || "Successfully completed #{title} bulk action"
      $table.one 'draw.dt', (e) -> $(e.target).DataTable().flash(success, 'success') and restoreSelected($(e.target), values)

    ).fail((response) ->
      error = response['message'] || "An error occured while attempting #{title} bulk action: #{response.statusText}"
      $table.one 'draw.dt', (e) -> $(e.target).DataTable().flash(error, 'danger') and restoreSelected($(e.target), values)

    ).always((response) ->
      $table.DataTable().draw()
    )

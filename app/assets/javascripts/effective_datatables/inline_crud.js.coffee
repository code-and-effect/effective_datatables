# To achieve inline crud, we use rails' data-remote links, and override their behaviour when inside a datatable
# This works with EffectiveForm.remote_form which is part of the effective_bootstrap gem.

# We click the New/Edit/Action button from the col-actions
$(document).on 'ajax:beforeSend', '.dataTables_wrapper .col-actions', (e, xhr, settings) ->
  $action = $(e.target)
  $table = $(e.target).closest('table')

  return true if ('' + $action.data('inline')) == 'false'

  $params =  $.param({_datatable_id: $table.data('id'), _datatable_attributes: $table.data('attributes'), _datatable_action: true })
  settings.url += (if settings.url.indexOf('?') == -1 then '?' else '&') + $params

  if $action.closest('.effective-datatables-inline-row,table.dataTable').hasClass('effective-datatables-inline-row')
    # Nothing.
  else if $action.closest('tr').parent().prop('tagName') == 'THEAD'
    beforeNew($action)
  else
    beforeEdit($action)

  true

# We have either completed the resource action, or fetched the inline form to load.
$(document).on 'ajax:success', '.dataTables_wrapper .col-actions', (event, data) ->
  $action = $(event.target)

  return true if ('' + $action.data('inline')) == 'false'

  if data.length > 0
    return true if data.indexOf('Turbolinks.clearCache()') == 0 && data.includes("Turbolinks.visit(")
    return true if data.indexOf('<html') >= 0

  if ($action.data('method') || 'get') == 'get'
    if $action.closest('tr').parent().prop('tagName') == 'THEAD' then afterNew($action) else afterEdit($action)
  else
    afterAction($action)

  EffectiveForm.remote_form_payload = ''
  EffectiveForm.remote_form_commit = ''
  EffectiveForm.remote_form_flash = ''
  EffectiveForm.remote_form_refresh_datatables = ''

  true

# There was an error completing something
$(document).on 'ajax:error', '.dataTables_wrapper', (event) ->
  $action = $(event.target)

  return true if ('' + $action.data('inline')) == 'false'

  afterError($action)

  EffectiveForm.remote_form_payload = ''
  EffectiveForm.remote_form_commit = ''
  EffectiveForm.remote_form_flash = ''
  EffectiveForm.remote_form_refresh_datatables = ''
  true

# Submitting an inline datatables form
$(document).on 'ajax:beforeSend', '.dataTables_wrapper .col-inline-form', (e, xhr, settings) ->
  $table = $(e.target).closest('table')

  $params = $.param({_datatable_id: $table.data('id'), _datatable_attributes: $table.data('attributes') })
  settings.url += (if settings.url.indexOf('?') == -1 then '?' else '&') + $params

  true

# The inline form has been submitted successfully
$(document).on 'effective-form:success', '.dataTables_wrapper .col-inline-form', (event, flash) ->
  $action = $(event.target)

  $tr = $action.closest('tr')
  $table = $tr.closest('table')

  if $tr.hasClass('effective-datatables-new-resource')
    $table.DataTable().flash(flash || 'Item created', 'success')
    $tr.fadeOut('slow')

    $actions = $table.children('thead').find('th.col-actions')
    $actions.children('svg').remove()
    $actions.children('a').fadeIn()
  else
    $table.DataTable().flash(flash || 'Item updated', 'success')
    $tr.fadeOut('slow')

  $table.DataTable().draw()
  refreshDatatables($table)

beforeNew = ($action) ->
  $table = $action.closest('table')
  $th = $action.closest('th')

  # Hide New Button
  $th.children('a').hide()

  # Append spinner and show Processing
  $th.append($table.data('spinner'))
  $table.DataTable().flash()
  $table.one 'draw.dt', (event) ->
    $th.find('a').show().siblings('svg').remove() if event.target == event.currentTarget

afterNew = ($action) ->
  $tr = $action.closest('tr')
  $table = $tr.closest('table')
  $action.siblings('svg').remove()

  html = buildRow($tr.children('th').length, EffectiveForm.remote_form_payload)

  $tr = $("<tr class='effective-datatables-inline-row effective-datatables-new-resource' role='row'>#{html}</tr>")
  $table.children('tbody').prepend($tr)

  expand($table)
  $tr.trigger('turbolinks:load')
  $tr.hide().fadeIn()

beforeEdit = ($action) ->
  $table = $action.closest('table')
  $td = $action.closest('td')

  # Hide dropdown
  $td.find('.dropdown-toggle').dropdown('toggle')
  $td.children('.btn-group').hide()
  $td.children('a').hide()

  # Append spinner and show Processing
  $td.append($table.data('spinner'))
  $table.DataTable().flash()

afterEdit = ($action) ->
  $tr = $action.closest('tr')
  $table = $tr.closest('table')

  html = buildRow($tr.children('td').length, EffectiveForm.remote_form_payload)

  $tr.data('inline-form-original-html', $tr.children().detach())
  $tr.html(html)
  $tr.addClass('effective-datatables-inline-row')

  expand($table)
  $tr.trigger('turbolinks:load')
  $tr.hide().fadeIn()

# This is when one of the resource actions completes
afterAction = ($action) ->
  $table = $action.closest('table')

  if EffectiveForm.remote_form_flash.length > 0
    flash = EffectiveForm.remote_form_flash[0]
    $table.DataTable().flash(flash[1], flash[0])
  else
    $table.DataTable().flash('Successfully ' + $action.attr('title'), 'success')

  unless redirectDatatables($table)
    $table.DataTable().draw()
    refreshDatatables($table)

afterError = ($action) ->
  $table = $action.closest('table')
  $td = $action.closest('td')

  # Show dropdown
  $td.children('.btn-group').show()

  # Hide spinner
  $td.children('svg').hide()

  # Cancel
  cancel($table)

  # Don't redraw
  $table.DataTable().flash('unable to ' + ($action.attr('title') || 'complete action'), 'danger')

buildRow = (length, payload) ->
  "<td class='col-inline-form' colspan='#{length-1}'><div class='container'>#{payload}</div></td>" +
  "<td class='col-actions col-actions-inline-form'>" +
    "<a href='#' class='btn btn-sm btn-outline-primary' title='Cancel' data-role='inline-form-cancel'>Cancel</a>" +
  "</td>"

expand = ($table) ->
  $wrapper = $table.closest('.dataTables_wrapper').addClass('effective-datatables-inline-expanded')
  $table.on 'draw.dt', (event) ->
    $wrapper.removeClass('effective-datatables-inline-expanded') if event.target == event.currentTarget

cancel = ($table) ->
  $wrapper = $table.closest('.dataTables_wrapper')
  if $wrapper.find('.effective-datatables-inline-row').length == 0
    $wrapper.removeClass('effective-datatables-inline-expanded')

redirectDatatables = ($source) ->
  return false unless EffectiveForm.remote_form_refresh_datatables.length > 0

  if EffectiveForm.remote_form_refresh_datatables.includes('refresh')
    if Turbolinks?
      Turbolinks.visit(window.location.href, { action: 'replace'})
    else
      window.location.reload()

    return true

  false

refreshDatatables = ($source) ->
  return unless EffectiveForm.remote_form_refresh_datatables.length > 0

  $('table.dataTable.initialized').each ->
    $table = $(this)

    if EffectiveForm.remote_form_refresh_datatables.find((id) -> $table.attr('id').startsWith(id) || id == 'all')
      $table.DataTable().draw() if $table != $source

# Cancel button clicked. Blow away new tr, or restore edit tr
# No data will have changed at this point
$(document).on 'click', ".dataTables_wrapper a[data-role='inline-form-cancel']", (event) ->
  $tr = $(event.currentTarget).closest('tr')

  if $tr.hasClass('effective-datatables-new-resource')
    $tr.fadeOut('slow', ->
      $table = $(this).closest('table')

      $actions = $table.children('thead').find('th.col-actions')
      $actions.children('svg').remove()
      $actions.children('a').fadeIn()

      $(this).remove()
      cancel($table)
    )
  else
    $tr.fadeOut('slow', ->
      $table = $(this).closest('table')
      $tr.html($tr.data('inline-form-original-html'))

      $td = $tr.children('.col-actions').first()
      $td.children('svg').remove()

      $toggle = $td.find('.dropdown-toggle')
      $toggle.dropdown('toggle') if $toggle.parent().hasClass('show')
      $td.children('.btn-group').show()
      $td.children('a').show()

      $tr.removeClass('effective-datatables-inline-row').fadeIn()
      cancel($table)
    )

  false

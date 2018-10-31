# To achieve inline crud, we use rails' data-remote links, and override their behaviour when inside a datatable
# This works with EffectiveForm.remote_form which is part of the effective_bootstrap gem.

# About to do a resource action, or fetch a partial. Show loading.
$(document).on 'ajax:beforeSend', '.dataTables_wrapper .col-actions', (e, xhr, settings) ->
  $action = $(e.target)
  $table = $(e.target).closest('table')

  return true if ('' + $action.data('inline')) == 'false'

  $params =  $.param({_datatable_id: $table.attr('id'), _datatable_cookie: $table.data('cookie') })
  settings.url += (if settings.url.indexOf('?') == -1 then '?' else '&') + $params

  if $action.closest('.effective-datatables-inline-row').length > 0
    # Nothing. This is a save action from within the inline form.
  else if $action.closest('tr').parent().prop('tagName') == 'THEAD'
    beforeNew($action)
  else
    beforeEdit($action)

  true

# We have either completed the resource action, or fetched the inline form to load.
$(document).on 'ajax:success', '.dataTables_wrapper .col-actions', (event) ->
  $action = $(event.target)

  return true if ('' + $action.data('inline')) == 'false'

  if ($action.data('method') || 'get') == 'get'
    if $action.closest('tr').parent().prop('tagName') == 'THEAD' then afterNew($action) else afterEdit($action)
  else
    afterAction($action)

  EffectiveForm.remote_form_payload = ''
  EffectiveForm.remote_form_flash = ''
  true

# The inline form has been submitted successfully
$(document).on 'effective-form:success', '.dataTables_wrapper .col-inline-form', (event, flash) ->
  $action = $(event.target)

  $tr = $action.closest('tr')
  $table = $tr.closest('table')

  if $tr.hasClass('effective-datatables-new-resource')
    $table.DataTable().flash(flash || 'Item created').draw()
    $tr.fadeOut('slow')

    $actions = $table.children('thead').find('th.col-actions')
    $actions.children('svg').remove()
    $actions.children('a').fadeIn()
  else
    $table.DataTable().flash(flash || 'Item updated').draw()
    $tr.fadeOut('slow')

# There was an error completing something
$(document).on 'ajax:error', '.dataTables_wrapper .col-inline-form', (event) ->
  $action = $(event.target)
  $table = $action.closest('table')
  $table.DataTable().flash('Error: unable to ' + ($action.attr('title') || 'complete action')).draw()

beforeNew = ($action) ->
  $table = $action.closest('table')
  $th = $action.closest('th')

  # Hide New Button
  $th.children('a').hide()

  # Append spinner and show Processing
  $th.append($table.data('spinner'))
  $table.DataTable().flash()
  $table.one 'draw.dt', (event) -> $th.find('a').show().siblings('svg').remove()

afterNew = ($action) ->
  $tr = $action.closest('tr')
  $table = $tr.closest('table')
  $action.siblings('svg').remove()

  html = buildRow($tr.children('th').length, EffectiveForm.remote_form_payload)

  $tr = $("<tr class='effective-datatables-inline-row effective-datatables-new-resource' role='row'>#{html}</tr>")
  $table.children('tbody').prepend($tr)

  expand($table)
  $tr.find('form').attr('data-remote', true).trigger('effective-bootstrap:initialize')
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
  $tr.data('inline-form-original-html', $tr.html())

  html = buildRow($tr.children('td').length, EffectiveForm.remote_form_payload)

  $tr.html(html)
  $tr.addClass('effective-datatables-inline-row')

  expand($table)
  $tr.find('form').attr('data-remote', true).trigger('effective-bootstrap:initialize')
  $tr.hide().fadeIn()

# This is when one of the resource actions completes
afterAction = ($action) ->
  $table = $action.closest('table')
  $table.DataTable().flash('Successful ' + $action.attr('title')).draw()

buildRow = (length, payload) ->
  "<td class='col-inline-form' colspan='#{length-1}'><div class='container'>#{payload}</div></td>" +
  "<td class='col-actions col-actions-inline-form'>" +
    "<a href='#' class='btn btn-sm btn-outline-primary' title='Cancel' data-role='inline-form-cancel'>Cancel</a>" +
  "</td>"

expand = ($table) ->
  $wrapper = $table.closest('.dataTables_wrapper').addClass('effective-datatables-inline-expanded')
  $table.one 'draw.dt', (event) -> $wrapper.removeClass('effective-datatables-inline-expanded')

cancel = ($table) ->
  $wrapper = $table.closest('.dataTables_wrapper')
  $wrapper.removeClass('effective-datatables-inline-expanded') if $wrapper.find('.effective-datatables-inline-row').length == 0

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

      $td.find('.dropdown-toggle').dropdown('toggle')
      $td.children('.btn-group').show()
      $td.children('a').show()

      $tr.removeClass('effective-datatables-inline-row').fadeIn()
      cancel($table)
    )

  false



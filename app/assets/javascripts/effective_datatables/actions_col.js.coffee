# To achieve inline crud, we use rails' data-remote links, and override their behaviour when inside a datatable
# This works with EffectiveForm.remote_form which is part of the effective_bootstrap gem.

# About to do a resource action, or fetch a partial. Show loading.
$(document).on 'ajax:beforeSend', '.dataTables_wrapper', (e) ->
  $action = $(e.target)

  if $action.closest('.effective-datatables-inline-row').length > 0
    # Nothing. This is a save action from within the inline form.
  else if $action.closest('tr').parent().prop('tagName') == 'THEAD'
    beforeNew($action)
  else
    beforeEdit($action)

  true

# We have either completed the resource action, or fetched the inline form to load.
$(document).on 'ajax:success', '.dataTables_wrapper', (e) ->
  $action = $(e.target)

  if ($action.data('method') || 'get') == 'get'
    if $action.closest('tr').parent().prop('tagName') == 'THEAD' then afterNew($action) else afterEdit($action)
  else
    afterAction($action)

  EffectiveForm.remote_form_payload = ''
  EffectiveForm.remote_form_flash = ''
  true

# The inline form has been submitted successfully
$(document).on '.dataTables_wrapper effective-form:success', (event, flash) ->
  $tr = $(event.target).closest('tr')
  $table = $tr.closest('table')

  if $tr.hasClass('effective-datatables-new-resource')
    $table.DataTable().flash(flash || 'Item created').draw()
    $tr.fadeOut('slow')

    $actions = $table.children('thead').find('th.col-actions')
    $actions.find('svg').remove()
    $actions.find('a').fadeIn()
  else
    $table.DataTable().flash(flash || 'Item updated').draw()
    $tr.fadeOut('slow')

# There was an error completing something
$(document).on 'ajax:error', '.dataTables_wrapper', (e) ->
  $action = $(e.target)
  $table = $action.closest('table')
  $table.DataTable().flash('Error: unable to ' + ($action.attr('title') || 'complete action')).draw()

## New Stuff ##
beforeNew = ($action) ->
  $table = $action.closest('table')
  $th = $action.closest('th')

  # Hide New Button
  $th.find('a').hide()

  # Append spinner and show Processing
  $th.append($table.data('spinner'))
  $table.DataTable().flash()
  $table.one 'draw.dt', (event) -> $th.find('a').show().siblings('svg').remove()

afterNew = ($action) ->
  $tr = $action.closest('tr')
  $action.siblings('svg').remove()

  html = buildRow($tr.children('th').length, EffectiveForm.remote_form_payload)

  $tr = $("<tr class='effective-datatables-inline-row effective-datatables-new-resource' role='row'>#{html}</tr>")
  $action.closest('table').find('tbody').prepend($tr)

  $tr.find('form').attr('data-remote', true).trigger('effective-bootstrap:initialize')
  $tr.hide().fadeIn()

beforeEdit = ($action) ->
  $table = $action.closest('table')
  $td = $action.closest('td')

  # Hide dropdown
  $td.find('.dropdown-toggle').dropdown('toggle')
  $td.find('.btn-group').hide()

  # Append spinner and show Processing
  $td.append($table.data('spinner'))
  $table.DataTable().flash()

afterEdit = ($action) ->
  $tr = $action.closest('tr')
  $tr.data('inline-form-original-html', $tr.html())

  html = buildRow($tr.children('td').length, EffectiveForm.remote_form_payload)

  $tr.html(html)
  $tr.addClass('effective-datatables-inline-row')

  $tr.find('form').attr('data-remote', true).trigger('effective-bootstrap:initialize')
  $tr.hide().fadeIn()

# This is when one of the resource actions completes
afterAction = ($action) ->
  $table = $action.closest('table')
  $table.DataTable().flash('Successful ' + $action.attr('title')).draw()

buildRow = (length, payload) ->
  "<td class='col-inline-form' colspan='#{length-1}'>#{payload}</td>" +
  "<td class='col-actions col-actions-inline-form'>" +
    "<a href='#' class='btn btn-outline-primary' title='Cancel' data-role='inline-form-cancel'>Cancel</a>" +
  "</td>"

# Cancel button clicked. Blow away new tr, or restore edit tr
# No data will have changed at this point
$(document).on 'click', ".dataTables_wrapper a[data-role='inline-form-cancel']", (event) ->
  $tr = $(event.currentTarget).closest('tr')

  if $tr.hasClass('effective-datatables-new-resource')
    $tr.fadeOut('slow', ->
      $actions = $(this).closest('table').children('thead').find('th.col-actions')
      $actions.find('svg').remove()
      $actions.find('a').fadeIn()

      $(this).remove()
    )
  else
    $tr.fadeOut('slow', ->
      $tr.html($tr.data('inline-form-original-html'))

      $td = $tr.children('.col-actions').first()
      $td.find('svg').remove()

      $td.find('.dropdown-toggle').dropdown('toggle')
      $td.find('.btn-group').show()

      $tr.removeClass('effective-datatables-inline-row')
      $tr.fadeIn()
    )

  false



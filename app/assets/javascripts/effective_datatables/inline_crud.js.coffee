# To achieve inline crud, we use rails' data-remote links, and override their behaviour when inside a datatable
# This works with EffectiveForm.remote_form which is part of the effective_bootstrap gem.

# https://github.com/rails/jquery-ujs/wiki/ajax
# https://edgeguides.rubyonrails.org/working_with_javascript_in_rails.html#rails-ujs-event-handlers

$(document).on 'ajax:before', '.dataTables_wrapper .col-actions', (event) ->
  $action = $(event.target)
  $table = $(event.target).closest('table')

  return true if ('' + $action.data('inline')) == 'false'

  $params = $.param(
    {
      _datatable_id: $table.attr('id'),
      _datatable_attributes: $table.data('attributes'),
      _datatable_action: true
    }
  )

  $action.attr('data-params', $params)
  true

# We click the New/Edit/Action button from the col-actions
$(document).on 'ajax:beforeSend', '.dataTables_wrapper .col-actions', (event, xhr, settings) ->
  [xhr, settings] = event.detail if event.detail # rails/ujs

  $action = $(event.target)
  $table = $(event.target).closest('table')

  return true if ('' + $action.data('inline')) == 'false'

  if $action.closest('.effective-datatables-inline-row,table.dataTable').hasClass('effective-datatables-inline-row')
    # Nothing.
  else if $action.closest('tr').parent().prop('tagName') == 'THEAD'
    beforeNew($action)
  else
    beforeEdit($action)

  true

# We have either completed the resource action, or fetched the inline form to load.
$(document).on 'ajax:success', '.dataTables_wrapper .col-actions', (event, data) ->
  [data, status, xhr] = event.detail if event.detail # rails/ujs

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

  true

# There was an error completing something
$(document).on 'ajax:error', '.dataTables_wrapper', (event) ->
  $action = $(event.target)

  return true if ('' + $action.data('inline')) == 'false'

  afterError($action)

  EffectiveForm.remote_form_payload = ''
  EffectiveForm.remote_form_commit = ''
  EffectiveForm.remote_form_flash = ''
  true

## Now for the fetched form. We add the datatables params attributes

$(document).on 'ajax:before', '.dataTables_wrapper .col-inline-form', (event) ->
  $action = $(event.target)
  $form = $action.closest('form')
  $table = $action.closest('table')

  if $form.find('input[name=_datatable_id]').length == 0
    $('<input>').attr(
      {type: 'hidden', name: '_datatable_id', value: $table.attr('id')}
    ).appendTo($form)

  if $form.find('input[name=_datatable_attributes]').length == 0
    $('<input>').attr(
      {type: 'hidden', name: '_datatable_attributes', value: $table.data('attributes')}
    ).appendTo($form)

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

  $table.DataTable().draw()

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

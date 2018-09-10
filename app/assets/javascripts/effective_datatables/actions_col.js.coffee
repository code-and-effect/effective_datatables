# We use the data-remote links and override all behaviour through those
$(document).on 'ajax:beforeSend', '.dataTables_wrapper', (e) ->
  $action = $(e.target)

  console.log 'ajax before send'

  if $action.closest('.effective-datatables-inline-form').length > 0
    beforeInlineFormSave($action)
  else if $action.closest('tr').parent().prop('tagName') == 'THEAD'
    beforeNew($action)
  else
    beforeEdit($action)

  true

$(document).on 'ajax:success', '.dataTables_wrapper', (e) ->
  $action = $(e.target)

  console.log 'ajax success'

  if ($action.data('method') || 'get') == 'get'
    if $action.closest('tr').parent().prop('tagName') == 'THEAD' then afterNew($action) else afterEdit($action)
  else
    afterAction($action)

  EffectiveForm.remote_form_payload = ''
  true

$(document).on 'ajax:error', '.dataTables_wrapper', (e, b, c) ->
  $action = $(e.target)
  $table = $action.closest('table')
  $table.DataTable().flash('Error: unable to ' + $action.attr('title')).draw()

## New Stuff ##
beforeNew = ($action) ->
  console.log 'before new'

  $table = $action.closest('table')
  $th = $action.closest('th')

  # Hide New Button
  $th.find('a').hide()

  # Append spinner and show Processing
  $th.append($table.data('spinner'))
  $table.DataTable().flash()

afterNew = ($action) ->
  console.log 'after new'

  $action.siblings('svg').hide()

  $tr = $action.closest('tr')
  length = $tr.children('th').length
  payload = EffectiveForm.remote_form_payload

  html =
    "<td class='effective-datatables-inline-form' colspan='#{length-1}'>#{payload}</td>" +
    "<td class='col-actions col-_actions col-actions-inline-form'>" +
      "<a href='#' class='btn btn-link' title='Close' data-role='inline-form-cancel'>Close</a>" +
    "</td>"

  $tr = $("<tr class='effective-datatables-new-resource' role='row'>#{html}</tr>")

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

  length = $tr.children('td').length
  payload = EffectiveForm.remote_form_payload

  html =
    "<td class='effective-datatables-inline-form' colspan='#{length-1}'>#{payload}</td>" +
    "<td class='col-actions col-_actions col-actions-inline-form'>" +
      "<a href='#' class='btn btn-link' title='Close' data-role='inline-form-cancel'>Close</a>" +
    "</td>"

  $tr.html(html)

  $tr.find('form').attr('data-remote', true).trigger('effective-bootstrap:initialize')
  $tr.hide().fadeIn()

# Submit made inside an inline-form
beforeInlineFormSave = ($action) ->
  # console.log 'submitted in form'

  # $btnClose = $action.closest('.effective-datatables-inline-form').siblings('.col-actions-inline-form').find("[data-role='inline-form-cancel']")
  # $btnClose.attr('data-role', 'inline-form-reset')

afterAction = ($action) ->
  $table = $action.closest('table')
  $table.DataTable().flash('Successful ' + $action.attr('title')).draw()

$(document).on 'click', ".dataTables_wrapper a[data-role='inline-form-cancel']", (event) ->
  $tr = $(event.currentTarget).closest('tr')

  if $tr.hasClass('effective-datatables-new-resource')
    $tr.fadeOut('slow', ->
      $actions = $(this).closest('table').children('thead').find('th.col-actions')
      $actions.find('svg').hide()
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

      $tr.fadeIn()
    )

  false

$(document).on '.dataTables_wrapper effective-form:success', (event) ->
  $tr = $(event.target).closest('tr')
  $table = $tr.closest('table')

  if $tr.hasClass('effective-datatables-new-resource')
    $table.DataTable().flash('Item created').draw()
    $tr.fadeOut('slow')

    $actions = $table.children('thead').find('th.col-actions')
    $actions.find('svg').hide()
    $actions.find('a').fadeIn()
  else
    $tr.closest('table').DataTable().flash('Item updated').draw()
    $tr.fadeOut('slow')

loadInlineForm = ($action, payload) ->
  $tr = $action.closest('tr')
  $tr.data('inline-form-original-html', $tr.html())

  tds = $tr.children('td').length

  html =
    "<td class='effective-datatables-inline-form' colspan='#{tds-1}'>#{payload}</td>" +
    "<td class='col-actions col-_actions col-actions-inline-form'>" +
      "<a href='#' class='btn btn-link' title='Close' data-role='inline-form-cancel'>Close</a>" +
    "</td>"

  $tr.html(html)

  # Post process. Make sure all the forms are remote ones
  $tr.find('form').attr('data-remote', true)
  $tr.trigger('effective-bootstrap:initialize')

  true

$(document).on 'click', ".dataTables_wrapper a[data-role='inline-form-cancel']", (event) ->
  $tr = $(event.currentTarget).closest('tr')

  # Put back the original html
  $tr.html($tr.data('inline-form-original-html'))

  # Undo any ajax:beforeSend stuff
  $td = $tr.children('.col-actions').first()

  # - Show dropdown
  $td.find('.dropdown-toggle').dropdown('toggle')
  $td.find('.btn-group').show()

  # - Remove spinner
  $td.find('svg').remove()

  false

$(document).on 'click', ".dataTables_wrapper a[data-role='inline-form-reset']", (event) ->
  $tr = $(event.currentTarget).closest('tr')

  # Put back the original html
  $tr.html($tr.data('inline-form-original-html'))

  $tr.closest('table').DataTable().draw()

  false

beforeNew = ($action) ->
  console.log 'new clicked'
  $table = $action.closest('table')

beforeEdit = ($action) ->
  $table = $action.closest('table')
  $td = $action.closest('td')

  # Hide dropdown
  $td.find('.dropdown-toggle').dropdown('toggle')
  $td.find('.btn-group').hide()

  # Append spinner and show Processing
  $td.append($table.data('spinner'))
  $table.DataTable().flash()

# Submit made inside an inline-form
beforeInlineFormSave = ($action) ->
  $btnClose = $action.closest('.effective-datatables-inline-form').siblings('.col-actions-inline-form').find("[data-role='inline-form-cancel']")
  $btnClose.attr('data-role', 'inline-form-reset')
  true

$(document).on 'ajax:beforeSend', '.dataTables_wrapper', (e, _, settings) ->
  $action = $(e.target)

  console.log 'ajax before send'

  if $action.closest('.effective-datatables-inline-form').length > 0
    beforeInlineFormSave($action)
  else if $action.closest('tr').parent().prop('tagName') == 'THEAD'
    beforeNew($action)
  else
    beforeEdit($action)

  true

afterNew = ($action) ->
  console.log 'after new'

afterEdit = ($action) ->
  loadInlineForm($action, EffectiveForm.remote_form_payload)
  EffectiveForm.remote_form_payload = ''

afterAction = ($action) ->
  $table = $action.closest('table')
  $table.DataTable().flash('Successful ' + $action.attr('title'))
  $table.DataTable().draw()

$(document).on 'ajax:success', '.dataTables_wrapper', (e) ->
  $action = $(e.target)

  console.log 'ajax success'

  if ($action.data('method') || 'get') == 'get'
    if $action.closest('tr').parent().prop('tagName') == 'THEAD'
      afterNew($action)
    else
      afterEdit($action)
  else
    afterAction($action)

$(document).on 'ajax:error', '.dataTables_wrapper', (e, b, c) ->
  console.log 'ajax error'

  $action = $(e.target)
  $table = $action.closest('table')

  $table.DataTable().flash('Error: unable to ' + $action.attr('title'))
  $table.DataTable().draw()

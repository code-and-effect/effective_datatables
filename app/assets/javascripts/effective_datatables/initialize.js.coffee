initializeDataTables = ->
  $('table.effective-datatable').each ->
    return if $.fn.DataTable.fnIsDataTable(this)

    datatable = $(this)
    input_js_options = datatable.data('input-js-options') || {}
    buttons_export_columns = input_js_options['buttons_export_columns'] || ':not(.col-actions)'

    if input_js_options['buttons'] == false
      input_js_options['buttons'] = []

    init_options =
      ajax: { url: datatable.data('source'), type: 'POST' }
      autoWidth: false
      buttons: [
        {
          extend: 'colvis',
          text: 'Show / Hide',
          postfixButtons: [
            { extend: 'colvisGroup', text: 'Show all', show: ':hidden'},
            { extend: 'colvisRestore', text: 'Show default'}
          ]
        },
        {
          extend: 'copy',
          exportOptions:
            format:
              header: (str) -> $("<div>#{str}</div>").children('.search-label').first().text()
            columns: buttons_export_columns
        },
        {
          extend: 'csv',
          exportOptions:
            format:
              header: (str) -> $("<div>#{str}</div>").children('.search-label').first().text()
            columns: buttons_export_columns
        },
        {
          extend: 'print',
          footer: true,
          exportOptions:
            format:
              header: (str) -> $("<div>#{str}</div>").children('.search-label').first().text()
            columns: ':visible:not(.col-actions)'
        },
      ]
      columns: datatable.data('columns')
      deferLoading: [datatable.data('display-records'), datatable.data('total-records')]
      deferRender: true
      displayStart: datatable.data('display-start')
      dom: "<'row'<'col-sm-12'B>><'row'<'col-sm-12'tr>><'row'<'col-sm-2'l><'col-sm-4'i><'col-sm-6'p>>"
      iDisplayLength: datatable.data('display-length')
      language: { 'lengthMenu': '_MENU_ per page'}
      lengthMenu: [[10, 25, 50, 100, 250, 1000, 9999999], ['10', '25', '50', '100', '250', '1000', 'All']]
      order: datatable.data('display-order')
      processing: true
      responsive: true
      serverParams: (params) ->
        api = this.api()
        api.columns().flatten().each (index) => params['columns'][index]['visible'] = api.column(index).visible()

        $table = $(api.table().node())
        $form = $(".effective-datatables-filters[aria-controls='#{$table.attr('id')}']").first()

        params['cookie'] = $table.data('cookie')

        if $form.length > 0
          params['scope'] = $form.find("input[id^='filters_scope']:checked").val() || ''
          params['filter'] = {}

          $form.find("[id^='filters_']:not(input[id^='filters_scope'])").each ->
            $input = $(this)
            params['filter'][$input.attr('id').substring(8, $input.attr('id').length)] = $input.val()

      serverSide: true
      scrollCollapse: true
      pagingType: 'simple_numbers'
      initComplete: (settings) ->
        initializeReset(this.api())
        initializeBulkActions(this.api())
        initializeSearch(this.api())
      drawCallback: (settings) ->
        $table = $(this.api().table().node())

        if settings['json']
          if settings['json']['effective_datatables_error']
            alert("DataTable error: #{settings['json']['effective_datatables_error']}\n\nPlease refresh the page and try again")
            return

          if settings['json']['aggregates']
            drawAggregates($table, settings['json']['aggregates'])

          if settings['json']['charts']
            drawCharts($table, settings['json']['charts'])

        drawBulkActions($table)

    # Copies the bulk actions html, stored in a data attribute on the table, into the buttons area
    initializeBulkActions = (api) ->
      $table = $(api.table().node())

      if $table.data('bulk-actions')
        $table.closest('.dataTables_wrapper').children().first().find('.dt-buttons').prepend($table.data('bulk-actions'))

    initializeReset = (api) ->
      $table = $(api.table().node())

      if $table.data('reset')
        $table.closest('.dataTables_wrapper').children().first().find('.dt-buttons').prepend($table.data('reset'))

    # After we perform a bulk action, we have to re-select the checkboxes manually and do a bit of house keeping
    drawBulkActions = ($table) ->
      selected = $table.data('bulk-actions-restore-selected-values')

      $bulkActions = $table.closest('.dataTables_wrapper').children().first().find('.buttons-bulk-actions').children('button')

      if selected && selected.length > 0
        $table.find("input[data-role='bulk-actions-resource']").each (_, input) ->
          $input = $(input)
          $input.prop('checked', selected.indexOf($input.val()) > -1)

        $bulkActions.removeAttr('disabled')
        $table.data('bulk-actions-restore-selected-values', [])
      else
        $bulkActions.attr('disabled', 'disabled')

    drawAggregates = ($table, aggregates) ->
      $tfoot = $table.find('tfoot').first()

      $.each aggregates, (row, values) =>
        $row = $tfoot.children().eq(row)

        if $row
          $.each values, (col, value) => $row.children().eq(col).html(value)

    drawCharts = ($table, charts) ->
      if typeof(google) != 'undefined' && typeof(google.visualization) != 'undefined'
        $.each charts, (name, data) =>
          $(".effective-datatables-chart[data-name='#{name}']").each (_, obj) =>
            chart = new google.visualization[data['type']](obj)
            chart.draw(google.visualization.arrayToDataTable(data['data']), data['options'])

    # Appends the search html, stored in the column definitions, into each column header
    initializeSearch = (api) ->
      api.columns().flatten().each (index) =>
        $th = $(api.column(index).header())
        settings = api.settings()[0].aoColumns[index] # column specific settings

        if settings.search != null # Assign preselected values
          api.settings()[0].aoPreSearchCols[index].sSearch = settings.search

        if settings.searchHtml  # Append the search html and initialize input events
          $th.append('<br>' + settings.searchHtml)
          initializeSearchEvents($th)

    # Sets up the proper events for each input
    initializeSearchEvents = ($th) ->
      $th.find('input,select').each (_, input) ->
        $input = $(input)

        return true if $input.attr('type') == 'hidden' || $input.attr('type') == 'checkbox'

        $input.parent().on 'click', (event) -> false # Dont order columns when you click inside the input
        $input.parent().on 'mousedown', (event) -> event.stopPropagation() # Dont order columns when you click inside the input

        if $input.is('select')
          $input.on 'change', (event) -> dataTableSearch($(event.currentTarget))
        else if $input.is('input')
          $input.delayedChange ($input) -> dataTableSearch($input)

    # Do the actual search
    dataTableSearch = ($input) ->   # This is the function called by a select or input to run the search
      return if $input.is(':invalid')

      table = $input.closest('table.dataTable')
      table.DataTable().column("#{$input.data('column-name')}:name").search($input.val()).draw()

    if input_js_options['simple'] == true
      init_options['dom'] = "<'row'<'col-sm-12'tr>>" # Just show the table
      datatable.addClass('simple')

    # Let's actually initialize the table now
    table = datatable.dataTable(jQuery.extend(init_options, input_js_options))

    # Apply EffectiveFormInputs to the Show x per page dropdown
    if datatable.data('effective-form-inputs')
      try table.closest('.dataTables_wrapper').find('.dataTables_length select').removeAttr('name').select2()

destroyDataTables = ->
  $('table.effective-datatable').each ->
    if $.fn.DataTable.fnIsDataTable(this)
      $(this).DataTable().destroy()

$ -> initializeDataTables()
$(document).on 'page:change', -> initializeDataTables()
$(document).on 'turbolinks:load', -> initializeDataTables()
$(document).on 'turbolinks:render', -> initializeDataTables()
$(document).on 'turbolinks:before-cache', -> destroyDataTables()




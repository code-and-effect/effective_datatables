initializeDataTables = (target) ->
  $(target || document).find('table.effective-datatable:not(.initialized)').each ->
    datatable = $(this)
    options = datatable.data('options') || {}
    buttons_export_columns = options['buttons_export_columns'] || ':not(.col-actions)'
    reorder = datatable.data('reorder')

    if options['buttons'] == false
      options['buttons'] = []

    init_options =
      ajax: { url: datatable.data('source'), type: 'POST' }
      autoWidth: false
      buttons: [
        {
          extend: 'colvis',
          postfixButtons: [
            { extend: 'colvisGroup', text: 'Show all', show: ':hidden', className: 'buttons-colvisGroup-first'},
            { extend: 'colvisGroup', text: 'Show none', hide: ':visible'}
            { extend: 'colvisRestore', text: 'Show default'}
          ]
        },
        {
          extend: 'copy',
          exportOptions:
            format:
              header: (str) -> $("<div>#{str}</div>").children('span').first().text()
            columns: buttons_export_columns
        },
        {
          extend: 'csv',
          exportOptions:
            format:
              header: (str) -> $("<div>#{str}</div>").children('span').first().text()
            columns: buttons_export_columns
        },
        {
          extend: 'print',
          footer: true,
          exportOptions:
            format:
              header: (str) -> $("<div>#{str}</div>").children('span').first().text()
            columns: ':visible:not(.col-actions)'
        },
      ]
      columns: datatable.data('columns')
      deferLoading: [datatable.data('display-records'), datatable.data('total-records')]
      deferRender: true
      displayStart: datatable.data('display-start')
      iDisplayLength: datatable.data('display-length')
      language: datatable.data('language')
      lengthMenu: [[5, 10, 25, 50, 100, 250, 500, 9999999], ['5', '10', '25', '50', '100', '250', '500', 'All']]
      order: datatable.data('display-order')
      processing: true
      responsive: true
      serverParams: (params) ->
        api = this.api()
        api.columns().flatten().each (index) => params['columns'][index]['visible'] = api.column(index).visible()

        $table = $(api.table().node())
        $form = $(".effective-datatables-filters[aria-controls='#{$table.attr('id')}']").first()

        params['cookie'] = $table.data('cookie')
        params['authenticity_token'] = $table.data('authenticity-token')

        if $form.length > 0
          params['scope'] = $form.find("input[name='filters[scope]']:checked").val() || ''
          params['filter'] = {}

          $form.find("select,textarea,input:not([type=submit])").each ->
            $input = $(this)

            if ['utf8', 'authenticity_token', 'filters[scope]'].includes($input.attr('name'))
              # Skipped
            else if $input.attr('type') == 'radio'
              name = $input.attr('name')
              filter_name = name.replace('filters[', '').substring(0, name.length-9)

              params['filter'][filter_name] = $form.find("input[name='#{name}']:checked").val()
              
            else if $input.attr('id')
              filter_name = $input.attr('id').replace('filters_', '')
              params['filter'][filter_name] = $input.val()

      serverSide: true
      scrollCollapse: true
      pagingType: 'simple_numbers'
      initComplete: (settings) ->
        initializeButtons(this.api())
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

          $table.children('tbody').trigger('effective-bootstrap:initialize')

    # Copies the bulk actions html, stored in a data attribute on the table, into the buttons area
    initializeButtons = (api) ->
      $table = $(api.table().node())
      $buttons = $table.closest('.dataTables_wrapper').children().first().find('.dt-buttons')

      if $table.data('reset')
        $buttons.prepend($table.data('reset'))

      if $table.data('reorder')
        $buttons.prepend($table.data('reorder'))

      if $table.data('bulk-actions')
        $buttons.prepend($table.data('bulk-actions'))

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
          $th.append(settings.searchHtml)
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
          $input.on('paste', -> dataTableSearch($input))

    # Do the actual search
    dataTableSearch = ($input) ->   # This is the function called by a select or input to run the search
      return if $input.is(':invalid')

      table = $input.closest('table.dataTable')
      table.DataTable().column("#{$input.data('column-name')}:name").search($input.val()).draw()

    if reorder
      init_options['rowReorder'] = { selector: 'td.col-_reorder', snapX: true, dataSrc: datatable.data('reorder-index') }

    # Let's actually initialize the table now
    table = datatable.dataTable(jQuery.extend(init_options, options))

    # Fix a tabindex issue
    table.children('tbody').children('tr').children('td[tabindex]').removeAttr('tabindex')

    # Apply EffectiveFormInputs to the Show x per page dropdown
    try table.closest('.dataTables_wrapper').find('.dataTables_length select').removeAttr('name').select2(minimumResultsForSearch: 100)

    if reorder
      table.DataTable().on('row-reorder', (event, diff, edit) -> $(event.target).DataTable().reorder(event, diff, edit))

    table.addClass('initialized')
    table.children('thead').trigger('effective-bootstrap:initialize')
    true

destroyDataTables = ->
  $('.effective-datatables-inline-expanded').removeClass('effective-datatables-inline-expanded')
  $('table.effective-datatable').each -> try $(this).removeClass('initialized').DataTable().destroy()

$ -> initializeDataTables()
$(document).on 'effective-datatables:initialize', (event) -> initializeDataTables(event.currentTarget)

$(document).on 'page:change', -> initializeDataTables()
$(document).on 'turbolinks:load', -> initializeDataTables()
$(document).on 'turbolinks:render', -> initializeDataTables()
$(document).on 'turbolinks:before-cache', -> destroyDataTables()

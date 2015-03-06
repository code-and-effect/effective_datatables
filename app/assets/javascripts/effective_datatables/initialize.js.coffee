initializeDataTables = ->
  $('table[data-effective-datatables-table]').each ->
    unless $.fn.DataTable.fnIsDataTable(this)
      datatable = $(this)

      aoColumnDefs = [
        { bSortable: false, aTargets: datatable.data('non-sortable') },
        { bVisible: false, aTargets: datatable.data('non-visible') }
      ].concat(datatable.data('column-classes') || [])

      init_options =
        bServerSide: true
        bProcessing: true
        bSaveState: true
        bAutoWidth: false
        deferRender: true
        order: datatable.data('default-order')
        sAjaxSource: datatable.data('source')
        pagingType: 'simple_numbers'
        lengthMenu: [[10, 25, 50, 100, 250, 1000, -1], [10, 25, 50, 100, 250, 1000, 'All']]
        iDisplayLength: 25
        fnServerParams: (aoData, a, b) ->
          table = this.DataTable()
          table.columns().flatten().each (index) ->  # Pass which columns are visible back to server
            aoData.push({'name': "sVisible_#{index}", 'value': table.column(index).visible()})

          # If this is the very first request to the server we have to manually set any selected filter options here
          # So that we can skip an fnFilter call in the dataTables.columnFilter that results in a double AJAX call
          ((sEcho = data; break) if data.name == 'sEcho') for data in aoData
          if sEcho && sEcho.value == 1
            $.each (datatable.data('filter') || []), (index, filter) ->
              if(filter.selected)
                sSearch = undefined
                ((sSearch = data; break) if data.name == "sSearch_#{index}") for data in aoData
                sSearch.value = filter.selected if sSearch

        aoColumnDefs: aoColumnDefs
        aoColumns: datatable.data('widths')
        oTableTools:
          sSwfPath: '/assets/effective_datatables/copy_csv_xls_pdf.swf',
          aButtons: ['csv', {'sExtends': 'xls', 'sButtonText': 'Excel'}, 'print']
        colVis:
          showAll: 'Show all'
          restore: 'Show default'
          activate: 'mouseover'
          fnStateChange: (iCol, bVisible) ->
            table = $(this.dom.button).closest('.dataTables_wrapper').children('table').first().DataTable()
            table.draw()

      simple = datatable.data('effective-datatables-table') == 'simple'
      filter = datatable.data('filter')

      if simple
        init_options['lengthMenu'] = [-1] # Show all results
        init_options['dom'] = "<'row'r>t" # Just show the table

      # Actually initialize it
      datatable = datatable.dataTable(init_options)

      if filter
        datatable.columnFilter
          sPlaceHolder: 'head:after'
          aoColumns : datatable.data('filter')
          bUseColVis: true

$ -> initializeDataTables()
$(document).on 'page:change', -> initializeDataTables()

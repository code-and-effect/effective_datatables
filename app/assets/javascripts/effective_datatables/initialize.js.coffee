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
        fnServerParams: (aoData, a, b) ->
          table = this.DataTable()
          table.columns().flatten().each (index) ->
            aoData.push({'name': "sVisible_#{index}", 'value': table.column(index).visible()})
        aoColumnDefs: aoColumnDefs
        aoColumns: datatable.data('widths')
        oTableTools:
          sSwfPath: '/assets/effective_datatables/copy_csv_xls_pdf.swf',
          aButtons: ['copy', 'csv', 'pdf', 'print']
        colVis:
          showAll: 'Show all'
          restore: 'Restore default visible'
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

  $('.dataTables_filter').each ->
    $(this).html("<button class='btn-reset-filters ColVis_Button' data-effective-datatables-reset-filters='true'><span>Reset Filters</span></button>")

$ -> initializeDataTables()
$(document).on 'page:change', -> initializeDataTables()

$(document).on 'click', '[data-effective-datatables-reset-filters]', (event) -> window.location.reload()

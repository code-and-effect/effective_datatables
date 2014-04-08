initializeDataTables = ->
  $('table[data-effective-datatables-table]').each ->
    unless $.fn.DataTable.fnIsDataTable(this)
      datatable = $(this)

      datatable.dataTable
        bServerSide: true
        bProcessing: true
        bSaveState: true
        sAjaxSource: datatable.data('source')
        sPaginationType: "bootstrap"
        aLengthMenu: [[10, 25, 50, 100, 250, 1000, -1], [10, 25, 50, 100, 250, 1000, 'All']]
        aoColumnDefs: 
          [
            {
              sDefaultContent: '-',
              aTargets: ['_all']
            },
            {
             bSortable: false,
             aTargets: datatable.data('non-sortable')
            }
          ]
        oTableTools:
          sSwfPath: '/assets/effective_datatables/copy_csv_xls_pdf.swf'
      .columnFilter
        sPlaceHolder: 'head:after'
        aoColumns : datatable.data('filter')

  $('.dataTables_filter').each ->
    $(this).html("<input type='button' class='btn' value='Clear Filters' data-effective-datatables-clear-filters='true'></input>")

$ -> initializeDataTables()
$(document).on 'page:change', -> initializeDataTables()

$(document).on 'click', '[data-effective-datatables-clear-filters]', (event) -> 
  #dataTable = $(this).closest('dataTables_wrapper').find('table').dataTable()
  window.location.reload()

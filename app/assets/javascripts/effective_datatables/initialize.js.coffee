initializeDataTables = ->
  $('table[data-effective-datatables-table]').each ->
    unless $.fn.DataTable.fnIsDataTable(this)
      datatable = $(this)

      datatable.dataTable
        bServerSide: true
        bProcessing: true
        bSaveState: true
        sAjaxSource: datatable.data('source')
        #sDom: "<'row'<'span4'l><'span4'T><'span4'f>r>t<'row'<'span6'i><'span6'p>>" boostrap2
        sDom: "<'row'<'col-xs-4'l><'col-xs-4'T><'col-xs-4'f>r>t<'row'<'col-xs-6'i><'col-xs-6'p>>"
        sPaginationType: "bootstrap"
        aLengthMenu: [[10, 25, 50, 100, 250, 1000, -1], [10, 25, 50, 100, 250, 1000, 'All']]
        aoColumnDefs: 
          [
            sDefaultContent: '-',
            aTargets: ['_all']
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

//= require dataTables/jquery.dataTables.min
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/dataTables.colReorder.min
//= require dataTables/dataTables.colVis.min
//= require dataTables/dataTables.tableTools.min
//= require vendor/jquery.debounce.min

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row header-row'<'col-sm-4'l><'col-sm-8'TC>r><'scroll_wrapper't><'row'<'col-md-6'i><'col-md-6'p>>"
});


//= require dataTables/jquery.dataTables.min
//= require dataTables/bootstrap/2/jquery.dataTables.bootstrap
//= require dataTables/dataTables.colReorder.min
//= require dataTables/dataTables.colVis.min
//= require dataTables/dataTables.fixedColumns
//= require dataTables/dataTables.tableTools.min
//= require vendor/jquery.debounce.min

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row'<'span6'><'span6'TCl>r><'scroll_wrapper't><'row'<'span6'i><'span6'p>>"
});

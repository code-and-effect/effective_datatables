//= require dataTables/jquery.dataTables.min
//= require dataTables/bootstrap/2/jquery.dataTables.bootstrap
//= require dataTables/dataTables.colVis.min
//= require dataTables/dataTables.tableTools.min
//= require dataTables/jquery.dataTables.columnFilter

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row'<'span6'l><'span6'TC>r>t<'row'<'span6'i><'span6'p>>"
});

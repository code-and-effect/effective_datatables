//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/2/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.tableTools
//= require dataTables/extras/dataTables.colVis
//= require vendor/jquery.dataTables.columnFilter

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row'<'span4'l><'span4'T><'span4'f>r>t<'row'<'span6'i><'span6'p>>"
});

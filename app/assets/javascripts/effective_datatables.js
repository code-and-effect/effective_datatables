//= require dataTables/jquery.dataTables.min
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/dataTables.tableTools.min
//= require dataTables/dataTables.colVis.min
//= require dataTables/jquery.dataTables.columnFilter

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row'<'col-xs-6'l><'col-xs-6'TC>r>t<'row'<'col-xs-6'i><'col-xs-6'p>>"
});


//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require dataTables/extras/dataTables.tableTools
//= require dataTables/extras/dataTables.colVis
//= require vendor/jquery.dataTables.columnFilter

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'sDom': "<'row'<'col-xs-4'l><'col-xs-4'T><'col-xs-4'fC>r>t<'row'<'col-xs-6'i><'col-xs-6'p>>"
});


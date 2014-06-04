//= require dataTables/jquery.dataTables
//= require dataTables/jquery.dataTables.bootstrap3
//= require dataTables/extras/ZeroClipboard
//= require dataTables/extras/dataTables.tableTools
//= require vendor/jquery.dataTables.columnFilter

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'sDom': "<'row'<'col-xs-4'l><'col-xs-4'T><'col-xs-4'f>r>t<'row'<'col-xs-6'i><'col-xs-6'p>>"
});


//= require dataTables/jquery.dataTables
//= require dataTables/jquery.dataTables.bootstrap
//= require dataTables/extras/ZeroClipboard
//= require dataTables/extras/TableTools
//= require vendor/jquery.dataTables.columnFilter

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'sDom': "<'row'<'span4'l><'span4'T><'span4'f>r>t<'row'<'span6'i><'span6'p>>"
});

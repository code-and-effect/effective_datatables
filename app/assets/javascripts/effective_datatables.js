//= require vendor/jquery.debounce.min
//= require vendor/jszip.min

//= require dataTables/jquery.dataTables.min
//= require dataTables/jquery.dataTables.bootstrap

//= require dataTables/buttons/dataTables.buttons
//= require dataTables/buttons/buttons.bootstrap
//= require dataTables/buttons/buttons.colVis
//= require dataTables/buttons/buttons.html5
//= require dataTables/buttons/buttons.print

//= require dataTables/dataTables.colReorder.min

//= require dataTables/responsive/dataTables.responsive.min
//= require dataTables/responsive/responsive.bootstrap.min

//= require_tree ./effective_datatables

$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row'<'col-sm-6'l><'col-sm-6'B>><'row'<'col-sm-12'tr>><'row'<'col-sm-5'i><'col-sm-7'p>>"
});

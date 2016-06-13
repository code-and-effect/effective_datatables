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

//= require effective_datatables/bulk_actions
//= require effective_datatables/responsive
//= require effective_datatables/scopes
//= require effective_datatables/initialize

$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row'<'col-sm-4'l><'col-sm-8'B>><'row'<'col-sm-12'tr>><'row'<'col-sm-6'i><'col-sm-6'p>>"
});

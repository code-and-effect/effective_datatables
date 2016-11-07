//= require vendor/jquery.delayedChange
//= require vendor/jquery.fileDownload
//= require dataTables/jszip/jszip

//= require dataTables/jquery.dataTables
//= require dataTables/dataTables.bootstrap

//= require dataTables/buttons/dataTables.buttons
//= require dataTables/buttons/buttons.bootstrap
//= require dataTables/buttons/buttons.colVis
//= require dataTables/buttons/buttons.html5
//= require dataTables/buttons/buttons.print
//= require dataTables/colreorder/dataTables.colReorder
//= require dataTables/responsive/dataTables.responsive
//= require dataTables/responsive/responsive.bootstrap

//= require effective_datatables/bulk_actions
//= require effective_datatables/responsive
//= require effective_datatables/scopes
//= require effective_datatables/charts

//= require effective_datatables/initialize

$.extend( $.fn.dataTable.defaults, {
  'dom': "<'row'<'col-sm-4'l><'col-sm-8'B>><'row'<'col-sm-12'tr>><'row'<'col-sm-6'i><'col-sm-6'p>>"
});

initializeCharts = ->
  $('.effective-datatables-chart:not(.initialized)').each ->
    $chart = $(this)

    data = $chart.data('data') || []
    as = $chart.data('as') || 'BarChart'
    options = $chart.data('options') || {}

    if google
      chart = new google.visualization[as](document.getElementById($chart.attr('id')))
      chart.draw(google.visualization.arrayToDataTable(data), options)

    $chart.addClass('initialized')

$ -> initializeCharts()
$(document).on 'page:change', -> initializeCharts()
$(document).on 'turbolinks:load', -> initializeCharts()

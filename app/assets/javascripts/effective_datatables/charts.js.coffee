initializeCharts = ->
  $('.effective-datatables-chart').each ->
    $chart = $(this)

    data = $chart.data('data') || []
    as = $chart.data('as') || 'BarChart'
    options = $chart.data('options') || {}

    if google
      chart = new google.visualization[as](document.getElementById($chart.attr('id')))
      chart.draw(google.visualization.arrayToDataTable(data), options)

$ -> initializeCharts()
$(document).on 'page:change', -> initializeCharts()
$(document).on 'turbolinks:load', -> initializeCharts()

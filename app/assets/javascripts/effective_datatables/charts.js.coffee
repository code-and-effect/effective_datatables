initializeCharts = ->
  $('.effective-datatables-chart').each ->
    $chart = $(this)

    data = $chart.data('data') || []
    type = $chart.data('type') || 'BarChart'
    options = $chart.data('options') || {}

    if google
      chart = new google.visualization[type](document.getElementById($chart.attr('id')))
      chart.draw(google.visualization.arrayToDataTable(data), options)

$ -> initializeCharts()
$(document).on 'page:change', -> initializeCharts()
$(document).on 'turbolinks:load', -> initializeCharts()

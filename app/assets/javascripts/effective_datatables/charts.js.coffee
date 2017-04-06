initializeCharts = ->
  $charts = $('.effective-datatables-chart:not(.initialized)')
  return unless $charts.length > 0

  if typeof(google) != 'undefined' && typeof(google.charts) != 'undefined'
    google.charts.load('current', { packages: ['corechart'] })
    google.charts.setOnLoadCallback(renderCharts)

  $charts.addClass('initialized')

renderCharts = ->
  return if (typeof(google) == 'undefined' || typeof(google.visualization) == 'undefined')

  $('.effective-datatables-chart').each ->
    $chart = $(this)

    data = $chart.data('data') || []
    type = $chart.data('type') || 'BarChart'
    options = $chart.data('options') || {}

    chart = new google.visualization[type](document.getElementById($chart.attr('id')))
    chart.draw(google.visualization.arrayToDataTable(data), options)

$ -> initializeCharts()
$(document).on 'page:change', -> initializeCharts()
$(document).on 'turbolinks:load', -> initializeCharts()

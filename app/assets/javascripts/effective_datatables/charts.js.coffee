initializeCharts = ->
  $charts = $('.effective-datatables-chart:not(.initialized)')
  return if $charts.length == 0

  if typeof(google) == 'undefined' || typeof(google.charts) == 'undefined'
    $.getScript 'https://www.gstatic.com/charts/loader.js', -> loadCharts()
  else
    loadCharts()

  $charts.addClass('initialized')

loadCharts = ->
  google.charts.load('current', { packages: ['corechart'] })
  google.charts.setOnLoadCallback(renderCharts)

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

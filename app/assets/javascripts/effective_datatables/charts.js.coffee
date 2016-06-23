# initializeReportTables = ->
#   $('table[data-effective-datatables-table]').each -> $(this).on('xhr', updateReportChart)

# initializeReportCharts = ->
#   $('div[data-effective-reports-chart]').each ->
#     report = $(this)

#     data = report.data('chartData') || []
#     type = report.data('chartType') || 'BarChart'
#     options = report.data('chartOptions') || {}

#     chart = new google.visualization[type](document.getElementById(report.attr('id')))
#     chart.draw(google.visualization.arrayToDataTable(data), options)

# # updateReportChart = (oSettings, json) ->
# #   console.log 'update report chart'
# #   chart_id = oSettings.currentTarget.id.replace('-table', '-chart')
# #   chart_obj = document.getElementById(chart_id)
# #   response = json.jqXHR.responseJSON

# #   if chart_obj && response
# #     data = response.chartData
# #     type = response.chartType
# #     options = response.chartOptions

# #     chart = new google.visualization[type](chart_obj)
# #     chart.draw(google.visualization.arrayToDataTable(data), options)

# $ ->
#   initializeReportTables()
#   initializeReportCharts()

# $(document).on 'page:change', ->
#   initializeReportTables()
#   initializeReportCharts()

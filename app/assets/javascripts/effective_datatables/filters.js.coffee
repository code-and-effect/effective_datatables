# Don't scope by .datatables_wrapper here, because it's out of the wrapper!
$(document).on 'click', 'a[data-apply-effective-datatables-filters]', (event) ->
  event.preventDefault()
  $form = $(event.currentTarget).closest('.effective-datatables-filters')
  $table = $('#' + $form.attr('aria-controls'))
  $table.DataTable().draw()

# Date Filters
# This uses moment.js. Sorry.
selectMonth = ($filter, date) ->
  prevDate = date.clone().subtract('1', 'month').startOf('month')
  startDate = date.clone().startOf('month')
  endDate = date.clone().endOf('month')
  nextDate = date.clone().add('1', 'month').startOf('month')

  # Update Previous Button
  $filter.find('[data-effective-datatables-filter-prev-month]').data('effective-datatables-filter-prev-month', prevDate.format('YYYY-MM-DD'))
  $filter.find('[data-effective-datatables-filter-prev-month]').find('span.prev-month').text(prevDate.format('MMM'))

  # Update Start and End Dates
  $filter.find('.start-date').text(startDate.format('YYYY-MM-DD'))
  $filter.find('.end-date').text(endDate.format('YYYY-MM-DD'))

  # Update Next Button
  $filter.find('[data-effective-datatables-filter-next-month]').data('effective-datatables-filter-next-month', nextDate.format('YYYY-MM-DD'))
  $filter.find('[data-effective-datatables-filter-next-month]').find('span.next-month').text(nextDate.format('MMM'))

  # Update hidden inputs
  $filter.find("input[id='filters_start_date']").data('DateTimePicker').date(startDate.format('YYYY-MM-DD'))
  $filter.find("input[id='filters_end_date']").data('DateTimePicker').date(endDate.format('YYYY-MM-DD'))

  $table = $('#' + $filter.closest('.effective-datatables-filters').attr('aria-controls'))
  $table.DataTable().draw()

$(document).on 'click', 'a[data-effective-datatables-filter-next-month]', (event) ->
  event.preventDefault()

  $obj = $(event.currentTarget)
  $filter = $obj.closest('.effective-datatables-filter')
  date = moment($obj.data('effective-datatables-filter-next-month'))

  selectMonth($filter, date)

$(document).on 'click', 'a[data-effective-datatables-filter-prev-month]', (event) ->
  event.preventDefault()

  $obj = $(event.currentTarget)
  $filter = $obj.closest('.effective-datatables-filter')
  date = moment($obj.data('effective-datatables-filter-prev-month'))

  selectMonth($filter, date)

## Years
selectYear = ($filter, date) ->
  prevDate = date.clone().subtract('1', 'year').startOf('year')
  startDate = date.clone().startOf('year')
  endDate = date.clone().endOf('year')
  nextDate = date.clone().add('1', 'year').startOf('year')

  # Update Previous Button
  $filter.find('[data-effective-datatables-filter-prev-year]').data('effective-datatables-filter-prev-year', prevDate.format('YYYY-MM-DD'))
  $filter.find('[data-effective-datatables-filter-prev-year]').find('span.prev-year').text(prevDate.format('YYYY'))

  # Update Start and End Dates
  $filter.find('.start-date').text(startDate.format('YYYY-MM-DD'))
  $filter.find('.end-date').text(endDate.format('YYYY-MM-DD'))

  # Update Next Button
  $filter.find('[data-effective-datatables-filter-next-year]').data('effective-datatables-filter-next-year', nextDate.format('YYYY-MM-DD'))
  $filter.find('[data-effective-datatables-filter-next-year]').find('span.next-year').text(nextDate.format('YYYY'))

  # Update hidden inputs
  $filter.find("input[id='filters_start_date']").data('DateTimePicker').date(startDate.format('YYYY-MM-DD'))
  $filter.find("input[id='filters_end_date']").data('DateTimePicker').date(endDate.format('YYYY-MM-DD'))

  $table = $('#' + $filter.closest('.effective-datatables-filters').attr('aria-controls'))
  $table.DataTable().draw()

$(document).on 'click', 'a[data-effective-datatables-filter-next-year]', (event) ->
  event.preventDefault()

  $obj = $(event.currentTarget)
  $filter = $obj.closest('.effective-datatables-filter')
  date = moment($obj.data('effective-datatables-filter-next-year'))

  selectYear($filter, date)

$(document).on 'click', 'a[data-effective-datatables-filter-prev-year]', (event) ->
  event.preventDefault()

  $obj = $(event.currentTarget)
  $filter = $obj.closest('.effective-datatables-filter')
  date = moment($obj.data('effective-datatables-filter-prev-year'))

  selectYear($filter, date)

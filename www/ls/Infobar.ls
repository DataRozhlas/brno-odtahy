monthNames= <[Leden Únor Březen Duben Květen Červen Červenec Srpen Září Říjen Listopad Prosinec]>
monthNames2 = <[ledna února března dubna května června července srpna září října listopadu prosince]>
window.ig.Infobar = class Infobar
  (parentElement, @fullData) ->
    ig.Events @
    @element = parentElement.append \div
      ..attr \class "infobar nodata"
    @heading = @element.append \h2
    @heading.html if ig.dir.split "-" .1 == "odtahy"
      "Statistiky odtahů"
    else
      "Statistiky přestupků"
    @heading.append \span
      ..attr \class \cancel
      ..html "<br>zrušit výběr"
      ..on \click ~>
        @emit \selectionCancelled
        @clearFilters!
        @drawWithData []
    @element.append \span
      ..attr \class \subtitle
      ..html "Kliknutím vyberte část města, která vás zajímá. Velikost výběru můžete změnit tlačítkem ◰ vlevo&nbsp;nahoře."
    totalElm = @element.append \span
      ..attr \class \total
    @total = totalElm.append \span
      ..attr \class \value
      ..html "0"
    @prestupkuVybranoElm = totalElm.append \span
      ..attr \class \suffix
      ..html " přestupků celkem"

    @timeFilters = []
    @dateFilters = []
    @initTimeHistogram!
    @initCalendar!

  initTimeHistogram: ->
    @timeHistogram = [0 til 24].map -> value: 0
    histogramContainer = @element.append \div
      ..attr \class "histogram-container"
      ..append \h3
        ..html if ig.dir.split "-" .1 == "odtahy" then "V kolik hodin se odtahuje" else "V kolik hodin se páchá nejvíce přestupků"
    @timeHistogramElm = histogramContainer.append \div
      ..attr \class "histogram time"
    @timeHistogramBars = @timeHistogramElm.selectAll \div.bar .data @timeHistogram .enter!append \div
      ..attr \class \bar
      ..on \click (d, i) ~> @toggleTimeFilter i
      ..append \span
        ..attr \class \legend
        ..html (d, i) -> i
    @timeHistogramBarFillsUnfiltered = @timeHistogramBars.append \div
      ..attr \class "fill bg"
    @timeHistogramBarFills = @timeHistogramBars.append \div
      ..attr \class \fill
      ..attr \data-tooltip "Kliknutím vyberte hodinu"

  initCalendar: ->
    startDate = new Date!
      ..setDate 1
      ..setMonth 0
      ..setFullYear 2014
      ..setHours 12
    months = for month in [0 til 12]
      {monthId: month, days: [], name: monthNames[month]}

    time = startDate.getTime!
    lastMonth = null
    index = 0
    @calendarColorScale = d3.scale.linear!
      ..range <[#cccccc #cfb0a7 #ce9384 #c97863 #c25a43 #b83a23 #ab0000]>
    @calendarDays  = {}
    @dayMaximum = -Infinity
    for i in [0 til 365]
      time += 86400 * 1e3
      day = startDate.getDay! - 1
      if day == -1 then day = 6
      month = startDate.getMonth!
      if month != lastMonth
        lastMonth = month
        index = day
      date = startDate.getDate!
      x = index % 7
      y = Math.floor index / 7
      id = "#{month}-#{date}"
      day = {day, date, month, time, index, x, y, value: 0, id}
      months[month].days.push day
      @calendarDays[id] = day
      index++
      startDate.setTime time

    @calendarElement = @element.append \div
      ..attr \class "calendar-container"
      ..append \h3
        ..html "V jaké dny se odtahuje"
      ..append \div
        ..attr \class "calendar"
        ..selectAll \div.month .data months .enter!append \div
          ..attr \class \month
          ..append \span
            ..attr \class \title
            ..html (.name)
          ..append \div
            ..attr \class \month-content
              ..selectAll \div.day .data (.days) .enter!append \div
                ..attr \class \day
                ..style \left -> "#{it.x * 11}px"
                ..style \top -> "#{it.y * 4}px"
                ..on \click ~> @toggleDateFilter it.id
                ..attr \data-tooltip -> "#{it.date}. #{monthNames2[it.month]}<br><small>Kliknutím vyberete pouze tento den</small>"
    @calendarDayElements = @calendarElement.selectAll \.day


  toggleTimeFilter: (startHour) ->
    index = @timeFilters.indexOf startHour
    if -1 isnt index
      @timeFilters.splice index, 1
    else
      @timeFilters.push startHour
    @updateFilteredView!

  toggleDateFilter: (day) ->
    index = @dateFilters.indexOf day
    if -1 isnt index
      @dateFilters.splice index, 1
    else
      @dateFilters.push day
    @updateFilteredView!

  clearFilters: ->
    @timeFilters.length = 0
    @dateFilters.length = 0

  updateFilteredView: ->
    @refilter!
    @recomputeGraphs!
    @refilterTimeHistogram!
    @refilterCalendar!
    @emit \updatedPoints @filteredData

  refilter: ->
    timeFiltersLen = @timeFilters.length
    dateFiltersLen = @dateFilters.length
    @filteredData = @unfilteredData.filter (datum) ~>
      if timeFiltersLen
        return false if datum.date.getHours! not in @timeFilters
      if dateFiltersLen
        return datum.dayId in @dateFilters
      return true

  draw: (bounds) ->
    str = JSON.stringify bounds
    return if str is @lastBoundsString
    @lastBoundsString = str
    @element.classed \nodata no
    bounds = L.latLngBounds bounds
    data = @fullData.filter -> bounds.contains it.latLng
    @drawWithData data

  drawWithData: (data = @fullData) ->
    @filteredData = @unfilteredData = data
    @element.classed \nodata @unfilteredData.length == 0
    @recomputeGraphs!
    @redrawGraphs!
    if @timeFilters.length || @dateFilters.length
      @updateFilteredView!
    else
      @emit \updatedPoints @filteredData


  recomputeGraphs: ->
    total = @filteredData.length
    @total.html ig.utils.formatNumber total
    @prestupkuVybranoElm.html switch
    | 5 > total > 1 => " přestupky vybrány"
    | total == 1 => " přestupek vybrán"
    | total == 15081 => "přestupků celkem"
    | otherwise => " přestupků vybráno"
    @reset!
    for line in @filteredData
      @timeHistogram[line.date.getHours!].value++
      day = @calendarDays[line.dayId]
        ..value++
      @dayMaximum = day.value if day.value > @dayMaximum

  redrawGraphs: ->
    @redrawTimeHistogram!
    @redrawCalendar!

  redrawTimeHistogram: ->
    @timeHistogramMax = d3.max @timeHistogram.map (.value) or 1
    @timeHistogramBarFillsUnfiltered
      ..style \height ~>
        "#{it.value / @timeHistogramMax * 100}%"
    @refilterTimeHistogram!

  redrawCalendar: ->
    domain = ig.utils.divideToParts [0, @dayMaximum], 7
    @calendarColorScale.domain domain
    @calendarDayElements
      ..style \background-color ~> @calendarColorScale it.value
      ..attr \data-tooltip ->
        plural = switch
        | it.value == 1 => "odtah"
        | 1 < it.value < 5 => "odtahy"
        | otherwise => "odtahů"
        "#{it.date}. #{monthNames2[it.month]}: #{it.value} #{plural}<br><small><em>Kliknutím vyberete pouze tento den</em></small>"

  refilterTimeHistogram: ->
    @timeHistogramBarFills
      ..style \height ~>
        "#{it.value / @timeHistogramMax * 100}%"

  refilterCalendar: ->
    @redrawCalendar!
    @calendarElement.classed \filtered @dateFilters.length > 0
    @calendarDayElements.classed \filtered ~> it.id in @dateFilters

  reset: ->
    for field in [@timeHistogram]
      for item in field
        item.value = 0
    for index, day of @calendarDays
      day.value = 0
    @dayMaximum = -Infinity

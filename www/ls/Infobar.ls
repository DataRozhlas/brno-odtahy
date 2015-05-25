monthNames= <[Leden Únor Březen Duben Květen Červen Červenec Srpen Září Říjen Listopad Prosinec]>
monthNames2 = <[ledna února března dubna května června července srpna září října listopadu prosince]>
window.ig.Infobar = class Infobar
  (parentElement, typy) ->
    ig.Events @
    @typy = typy.map -> {name: it.text, id: it.id, value: 0}
    @typyAssoc = @typy.slice!
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
      ..html " přestupků vybráno"

    @timeFilters = []
    @dateFilters = []
    @typFilters  = []
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
      ..setMonth 2
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
      day = {day, date, month, time, index, x, y, value: 0}
      months[month].days.push day
      @calendarDays["#{month}-#{date}"] = day
      index++
      startDate.setTime time

    calendarElement = @element.append \div
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
              ..attr \data-tooltip -> "#{it.date}. #{monthNames2[it.month]}"
    @calendarDayElements = calendarElement.selectAll \.day


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

  toggleTypFilter: (typ) ->
    typId = typ.id
    if typ.isFiltered
      @typFilters.splice do
        @typFilters.indexOf typId
        1
    else
      @typFilters.push typId
    typ.isFiltered = !typ.isFiltered
    @updateFilteredView!

  clearFilters: ->
    @timeFilters.length = 0
    @dateFilters.length = 0
    @typFilters.length = 0

  updateFilteredView: ->
    @refilter!
    @recomputeGraphs!
    @refilterTimeHistogram!
    @emit \updatedPoints @filteredData

  refilter: ->
    timeFiltersLen = @timeFilters.length
    dateFiltersLen = @dateFilters.length
    typFiltersLen  = @typFilters.length
    @filteredData = @fullData.filter (datum) ~>
      if timeFiltersLen
        return false unless datum.hasHours
        return false if datum.date.getHours! not in @timeFilters
      if dateFiltersLen
        return false unless datum.date
        return false if datum.day not in @dateFilters
      if typFiltersLen
        return false if datum.typId not in @typFilters
      return true

  draw: (bounds) ->
    str = JSON.stringify bounds
    return if str is @lastBoundsString
    @lastBoundsString = str
    @element.classed \nodata no
    (err, data) <~ downloadBounds bounds
    @drawWithData data

  drawWithData: (data) ->
    @filteredData = @fullData = data
    if @fullData.length == 0
      @element.classed \nodata yes
    @recomputeGraphs!
    for typ in @typy
      typ.fullValue = typ.value
    @redrawGraphs!
    if @timeFilters.length || @dateFilters.length || @typFilters.length
      @updateFilteredView!
    else
      @emit \updatedPoints @filteredData


  recomputeGraphs: ->
    total = @filteredData.length
    @total.html ig.utils.formatNumber total
    @prestupkuVybranoElm.html switch
    | 5 > total > 1 => " přestupky vybrány"
    | total == 1 => " přestupek vybrán"
    | otherwise => " přestupků vybráno"
    @reset!
    for line in @filteredData
      if line.date
        if line.hasHours
          h = line.date.getHours!
          @timeHistogram[h].value++
        day = @calendarDays["#{line.date.getMonth!}-#{line.date.getDate!}"]
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
    @calendarDayElements.style \background-color ~> @calendarColorScale it.value

  refilterTimeHistogram: ->
    @timeHistogramBarFills
      ..style \height ~>
        "#{it.value / @timeHistogramMax * 100}%"

  reset: ->
    for field in [@timeHistogram]
      for item in field
        item.value = 0
    for index, day of @calendarDays
      day.value = 0
    @dayMaximum = -Infinity

currBounds = null
downloadBounds = (bounds, cb) ->
  xBounds = [bounds.0.1, bounds.1.1]
  yBounds = [bounds.0.0, bounds.1.0]
  [xBounds, yBounds].forEach -> it.sort (a, b) -> a - b
  files = getRequiredFiles xBounds, yBounds
  currBounds := [xBounds, yBounds]
  (err, lines) <~ downloadFiles files
  return if lines is null
  inboundLines = lines.filter ({x, y}) ->
    currBounds.0.0 <= x <= currBounds.0.1 and currBounds.1.0 <= y <= currBounds.1.1
  cb err, inboundLines

cache = {}
downloadFiles = (files, cb) ->
  id = files.join '+'
  if cache[id] isnt void
    cb null, cache[id]
  else
    cache[id] = null
    (err, data) <- async.map files, (file, cb) ->
      (err, data) <~ d3.tsv do
        "../data/processed/#{ig.dir}/tiles/#file"
        (line) ->
          if line.spachano
            [year, month, day, hour] =
              parseInt (line.spachano.substr 0, 2), 10
              parseInt (line.spachano.substr 2, 2), 10
              parseInt (line.spachano.substr 4, 2), 10
              parseInt (line.spachano.substr 6, 2), 10
            line.date = new Date!
              ..setTime 0
              ..setFullYear year
              ..setMonth month - 1
              ..setDate day
            if !isNaN hour
              line.date.setHours hour
              line.hasHours = yes
            line.day = line.date.getDay! - 1
            if line.day == -1 then line.day = 6 # nedele na konec tydne
          line.x = parseFloat line.x
          line.y = parseFloat line.y
          line.typId = parseInt line.typ, 10
          # TODO: typ, spachano date
          line
      cb null, data || []
    all = [].concat ...data
    cache[id] = all
    cb null, all

getRequiredFiles = (x, y) ->
  xIndices = x.map getXIndex
  yIndices = y.map getYIndex
  files = []
  for xIndex in [xIndices.0 to xIndices.1]
    for yIndex in [yIndices.0 to yIndices.1]
      files.push "#{xIndex}-#{yIndex}.tsv"
  files

getXIndex = -> Math.floor it / 0.01
getYIndex = -> Math.floor it / 0.005

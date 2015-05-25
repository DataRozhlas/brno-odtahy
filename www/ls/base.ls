ig = window.ig
init = ->
  tooltip = new Tooltip!watchElements!
  [filter, location] = window.location.hash.substr 1 .split ':'
  ig.dir = "brno-odtahy"
  ig.isRychlost = false
  container = d3.select ig.containers.base
  points = d3.tsv.parse ig.data.odtahy, (row) ->
    row.x = parseFloat row.x
    row.y = parseFloat row.y
    row.latLng = L.latLng row.y, row.x
    row.cisteni = row.cisteni == "1"
    [d, m, y] = row.datum.split "." .map parseInt _, 10
    [h, i] = row.cas.split ":" .map parseInt _, 10
    row.date = new Date!
      ..setTime 0
      ..setDate d
      ..setMonth m - 1
      ..setYear 2000 + y
      ..setHours h
      ..setMinutes i
    row.dayId = "#{row.date.getMonth!}-#{row.date.getDate!}"
    row
  switch filter
    | \cisteni => points .= filter -> it.cisteni
    | \policie => points .= filter -> !it.cisteni
  map = new ig.Map ig.containers.base
    ..drawHeatmap points

  infobar = new ig.Infobar container, points
  map
    ..on \selection infobar~draw
    ..on \markerClicked infobar~clearFilters
  heatmapLastPointList = null
  mapTimeout = null
  lastHeatCall = 0
  throttleHeatmap = (pointList) ->
    heatmapLastPointList := pointList
    return if mapTimeout isnt null
    nextCall = Math.max do
      lastHeatCall - Date.now! + 500
      0
    mapTimeout := setTimeout do
      ->
        map.drawFilteredPoints heatmapLastPointList
        lastHeatCall := Date.now!
        mapTimeout := null
      nextCall

  infobar
    ..on \updatedPoints throttleHeatmap
    ..on \selectionCancelled map~cancelSelection
    ..drawWithData!
  geocoder = new ig.Geocoder ig.containers.base
    ..on \latLng (latlng) ->
      map.map.setView latlng, 18
      map.onMapChange!
  shareDialog = new ig.ShareDialog ig.containers.base
    ..on \hashRequested ->
      center = map.map.getCenter!
      shareDialog.setHash "#{ig.dir}:#{center.lat.toFixed 4},#{center.lng.toFixed 4},#{map.map.getZoom!}"
  new ig.EmbedLogo ig.containers.base, dark: yes
  handleHashLocation = (hashLocation) ->
    [lat, lon, zoom] = hashLocation.split /[^-\.0-9]+/
    lat = parseFloat lat
    lon = parseFloat lon
    zoom = parseFloat zoom
    if lat and lon and zoom >= 0
      map.map.setView [lat, lon], zoom


  if location
    handleHashLocation location

  window.onhashchange = ->
    [dir, location] = window.location.hash.substr 1 .split ':'
    if location
      handleHashLocation location
if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!

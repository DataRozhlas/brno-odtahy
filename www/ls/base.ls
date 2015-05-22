ig = window.ig
init = ->
  tooltip = new Tooltip!watchElements!
  [dir, location] = window.location.hash.substr 1 .split ':'
  ig.dir = dir = "brno-odtahy"
  ig.isRychlost = \rychlost == ig.dir.substr -8
  container = d3.select ig.containers.base
  if ig.isRychlost then container.classed \rychlost yes
  map = new ig.Map ig.containers.base
    ..drawHeatmap dir
  (err, data) <~ d3.text "../data/processed/#dir/typy.tsv"
  ig.typy = typy = for text, id in data.split "\n"
    {text, id}
  infobar = new ig.Infobar container, typy
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
        map.drawFilteredHeatmap heatmapLastPointList
        lastHeatCall := Date.now!
        mapTimeout := null
      nextCall

  infobar
    ..on \updatedPoints throttleHeatmap
    ..on \selectionCancelled map~cancelSelection
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

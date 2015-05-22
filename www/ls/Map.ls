
window.ig.Map = class Map
  (parentElement) ->
    @tooltip = new Tooltip!
    mapElement = document.createElement 'div'
      ..id = \map
    @markerDrawn = yes
    window.ig.Events @
    parentElement.appendChild mapElement
    @groupedLatLngs = []
    @markerRadiusScale = if ig.isRychlost
      d3.scale.sqrt!
        ..domain [1 50 1000 10000 100000 999999]
        ..range [20 40 50 60 70 80]
    else
      d3.scale.sqrt!
        ..domain [1 50 150 999999]
        ..range [30 35 45 45]
    @markerColorScale = if ig.isRychlost
      d3.scale.linear!
        ..domain [1 10 100 1000 10000 50000 999999]
        ..range <[#feb24c #fd8d3c #fc4e2a #e31a1c #bd0026 #800026 #800026]>
    else
      d3.scale.linear!
        ..domain [1 10 100 1000 10000 999999]
        ..range <[#fd8d3c #fc4e2a #e31a1c #bd0026 #800026 #800026]>
    @currentMarkers = []
    switch ig.dir.substr 0, 5
    | \praha
      bounds =
        x: [14.263 14.689]
        y: [49.952 50.171]
      center = [(bounds.y.0 + bounds.y.1) / 2, (bounds.x.0 + bounds.x.1) / 2]
      center.0 += 0.023
      center.1 -= 0.04
      zoom = 13
      if ig.isRychlost
        zoom = 12
        center = [50.06199 14.4070]
      maxBounds = [[49.94,14.24], [50.18,14.7]]
    | \tepli
      bounds =
        x: [13.792 13.862]
        y: [50.622 50.665]
      center = [(bounds.y.0 + bounds.y.1) / 2, (bounds.x.0 + bounds.x.1) / 2]
      center.0 -= 0.005
      center.1 -= 0.004
      zoom = 15
      maxBounds = [[50.61 13.78], [50.68, 13.95]]

    | otherwise
      bounds =
        x: [16.475 16.716]
        y: [49.124 49.289]
      zoom = 14
      center = [(bounds.y.0 + bounds.y.1) / 2, (bounds.x.0 + bounds.x.1) / 2]
      center.0 -= 0.01
      center.1 += 0.01
      if ig.isRychlost
        zoom = 13
        center = [49.1849 16.6344]
      maxBounds = [[49.11 16.46] [49.30 16.74]]

    @map = L.map do
      * mapElement
      * minZoom: 12,
        maxZoom: 18,
        zoom: zoom,
        center: center
        maxBounds: maxBounds

    @markerLayer = L.layerGroup!

    baseLayer = L.tileLayer do
      * "https://samizdat.cz/tiles/ton_b1/{z}/{x}/{y}.png"
      * zIndex: 1
        opacity: 1
        attribution: 'mapová data &copy; přispěvatelé <a target="_blank" href="http://osm.org">OpenStreetMap</a>, obrazový podkres <a target="_blank" href="http://stamen.com">Stamen</a>, <a target="_blank" href="https://samizdat.cz">Samizdat</a>'

    labelLayer = L.tileLayer do
      * "https://samizdat.cz/tiles/ton_l1/{z}/{x}/{y}.png"
      * zIndex: 3
        opacity: 0.75

    @map.addLayer baseLayer
    @map.addLayer labelLayer
    @initSelectionRectangle!
    draggerButton = document.createElement 'div'
      ..innerHTML = '◰'
      ..className = 'draggerButton'
      ..setAttribute \title "Zapnout režim výběru oblasti a vypnout posouvání mapy myší"
    parentElement.appendChild draggerButton
    @draggingButtonEnabled = no
    self = @
    draggerButton.addEventListener "mousedown" (.preventDefault!)
    draggerButton.addEventListener "click" (evt) ->
      self.draggingButtonEnabled = !self.draggingButtonEnabled
      if self.draggingButtonEnabled
        @className = "draggerButton active"
        self.enableSelectionRectangle!
      else
        @className = "draggerButton"
        self.disableSelectionRectangle!

    document.addEventListener "keydown" (evt) ~>
      if evt.ctrlKey
        if @draggingButtonEnabled
          @disableSelectionRectangle!
        else
          @enableSelectionRectangle!
    document.addEventListener "keyup" (evt) ~>
      if !evt.ctrlKey
        if @draggingButtonEnabled
          @enableSelectionRectangle!
        else
          @disableSelectionRectangle!
    @map
      ..on \click (evt) ~>
        unless evt.originalEvent.ctrlKey or @draggingButtonEnabled
          @addMiniRectangle evt.latlng
      ..on \moveend @~onMapChange

  onMapChange: ->
    zoom = @map.getZoom!
    shouldDrawMarkers = zoom >= 17
      or (\teplice is ig.dir.substr 0, 7 and zoom >= 15)
      or (ig.isRychlost)
    if shouldDrawMarkers
      @drawMarkers! if !@markersDrawn
      @updateMarkers!
    else if zoom < 17 and @markersDrawn
      @hideMarkers!

  drawMarkers: ->
    @map.removeLayer @heatLayer
    @map.removeLayer @heatFilteredLayer if @heatFilteredLayer
    @map.addLayer @markerLayer
    @markersDrawn = yes

  updateMarkers: ->
    bounds = @map.getBounds!
    displayedLatLngs = {}
    @currentMarkers .= filter (marker) ~>
      latLng = marker.getLatLng!
      id = "#{latLng.lat}-#{latLng.lng}"
      contains = bounds.contains latLng
      if not contains
        @markerLayer.removeLayer marker
        no
      else
        displayedLatLngs[id] = 1
        yes
    latLngsToDisplay = @groupedLatLngs.filter ->
      if bounds.contains it
        id = "#{it.lat}-#{it.lng}"
        if displayedLatLngs[id]
          no
        else
          yes
      else
        no
    latLngsToDisplay.forEach (latLng) ~>
      count = latLng.alt
      color = @markerColorScale count
      radius = Math.floor @markerRadiusScale count
      icon = L.divIcon do
        html: "<div style='background-color: #color;line-height:#{radius}px'>#{ig.utils.formatNumber count}</div>"
        iconSize: [radius + 10, radius + 10]
      marker = L.marker latLng, {icon}
        ..on \click ~>
          @emit \markerClicked marker
          @addMicroRectangle latLng
      if latLng.address
        marker
          ..on \mouseover ~> @tooltip.display latLng.address
          ..on \mouseout ~> @tooltip.hide!

      @currentMarkers.push marker
      @markerLayer.addLayer marker

  hideMarkers: ->
    @markersDrawn = no
    @map.addLayer @heatLayer
    @map.addLayer @heatFilteredLayer if @heatFilteredLayer
    @map.removeLayer @markerLayer

  drawHeatmap: (dir) ->
    (err, data) <~ d3.tsv "../data/processed/#dir/grouped.tsv", (line) ->
      line.x = parseFloat line.x
      line.y = parseFloat line.y
      # line.typ = parseInt line.typ, 10
      line.count = parseInt line.count, 10
      line
    # data .= filter -> -1 != window.ig.typy[it.typ].indexOf "rychlost"
    latLngs = for item in data
      latlng = L.latLng item.y, item.x
        ..alt = item.count
        ..address = item.address
      latlng
    @groupedLatLngs = latLngs

    options =
      radius: 8
    @heatLayer = L.heatLayer latLngs, options
      ..addTo @map
    @heatFilteredLayer = L.heatLayer [], options
      ..addTo @map
    @onMapChange!

  drawFilteredHeatmap: (pointList) ->
    return if @markerDrawn
    if pointList.length
      @desaturateHeatmap!
      options =
        radius: 8
      latLngs = for item in pointList
        L.latLng item.y, item.x
      @heatFilteredLayer.setLatLngs latLngs
    else
      @heatFilteredLayer.setLatLngs []
      @resaturateHeatmap!


  desaturateHeatmap: ->
    return if @heatmapIsDesaturated
    @heatmapIsDesaturated = yes
    gradient =
      0.4: '#d9d9d9'
      0.7: '#bdbdbd'
      0.9: '#737373'
      1.0: '#525252'
    @heatLayer.setOptions {gradient}

  resaturateHeatmap: ->
    return unless @heatmapIsDesaturated
    @heatmapIsDesaturated = no
    gradient =
      0.4: 'blue'
      0.6: 'cyan'
      0.7: 'lime'
      0.8: 'yellow'
      1.0: 'red'
    @heatLayer.setOptions {gradient}

  initSelectionRectangle: ->
    @selectionRectangleDrawing = no
    @selectionRectangle = L.rectangle do
      * [0,0], [0, 0]
    @selectionRectangle.addTo @map

  enableSelectionRectangle: ->
    @selectionRectangleEnabled = yes
    @map
      ..dragging.disable!
      ..on \mousedown (evt) ~>
        @selectionRectangleDrawing = yes
        @startLatlng = evt.latlng
      ..on \mousemove (evt) ~>
        return unless @selectionRectangleDrawing
        @endLatlng = evt.latlng
        @selectionRectangle.setBounds [@startLatlng, @endLatlng]
        @setSelection [[@startLatlng.lat, @startLatlng.lng], [@endLatlng.lat, @endLatlng.lng]]
      ..on \mouseup ~>
        @selectionRectangleDrawing = no

  disableSelectionRectangle: ->
    @selectionRectangleEnabled = no
    @map
      ..dragging.enable!
      ..off \mousedown
      ..off \mousemove
      ..off \mouseup

  setSelection: (bounds) ->
    @markerDrawn = no
    @emit \selection bounds

  addMiniRectangle: (latlng) ->
    startLatlng =
      latlng.lat - 0.001
      latlng.lng - 0.0015

    endLatlng =
      latlng.lat + 0.001
      latlng.lng + 0.0015

    @selectionRectangle.setBounds [startLatlng, endLatlng]
    @setSelection [startLatlng, endLatlng]

  addMicroRectangle: (latlng) ->
    @markerDrawn = yes
    @cancelSelection!
    startLatlng =
      latlng.lat
      latlng.lng

    endLatlng =
      latlng.lat
      latlng.lng

    @emit \selection [startLatlng, endLatlng]

  cancelSelection: ->
    @selectionRectangle.setBounds [[0, 0], [0, 0]]

window.ig.Geocoder = class Geocoder
  (@baseElement) ->
    ig.Events @
    geocoder = null
    form = document.createElement \form
      ..id = "frm-geocode"
    label = document.createElement \label
      ..innerHTML = "Najít místo"
    inputs = document.createElement \div
      ..className = "inputs"

    inputText = document.createElement \input
      ..type = \text
      ..setAttribute? \placeholder "Vinohradská 12"
    inputButton = document.createElement \input
      ..type = \submit
      ..value = "Najít"
    inputs
      ..appendChild inputText
      ..appendChild inputButton

    form
      ..appendChild label
      ..appendChild inputs
      ..addEventListener \submit (evt) ~>
        evt.preventDefault!
        geocoder := new google.maps.Geocoder! if not geocoder
        address = inputText.value
        ga? \send \event \geocoder \geocode address
        bounds = new google.maps.LatLngBounds do
          new google.maps.LatLng 48.3 11.6
          new google.maps.LatLng 51.3 19.1
        address += ", " + ig.dir.split '-' .0
        (results, status) <~ geocoder.geocode {address, bounds}
        if status != google.maps.GeocoderStatus.OK or !results.length
          alert "Bohužel, danou adresu nebylo možné najít"
          return
        result = results.0
        latlng = [result.geometry.location.lat!, result.geometry.location.lng!]
        @emit \latLng latlng

    @baseElement
      ..appendChild form

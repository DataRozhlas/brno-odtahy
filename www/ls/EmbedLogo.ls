ig.EmbedLogo = class EmbedLogo
  (@parentElement, @options = {}) ->
    @display! if @shouldBeDisplayed!

  display: ->
    {dark} = @options
    imgName = if dark then 'cro-logo' else 'cro-logo-light'
    src = "/tools/cro-logo/#imgName.svg"
    classNames = []
    element = document.createElement \div
      ..id = "embedLogo"
      ..innerHTML = "<a href='http://www.rozhlas.cz/zpravy/data/' target='_blank'><img src='#src' alt='Vytvořil Český rozhlas' title='Vytvořil Český rozhlas'></a>"
    element.querySelector 'a' .onclick = ->
      ga? \send \event \embedLogo \click
    @parentElement.appendChild element

  shouldBeDisplayed: ->
    url = document.referrer
    return true if not url
    sansProtocol = url.split "//" .1
    domain = sansProtocol.split "/" .0
    alloweds = <[rozhlas.cz]>
    for allowed in alloweds
      if allowed is domain.substr -1 * allowed.length
        return false
    return true

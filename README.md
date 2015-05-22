# Mapa přestupků v agendě městských policií Prahy, Brna a Teplicích

Články na [Rozhlas.cz](http://www.rozhlas.cz/zpravy/portal/)
  * [Unikátni mapa: Podívejte se, kde dostávaji řidiči v Praze nejvíc pokut za rychlost](http://www.rozhlas.cz/zpravy/data/_zprava/unikatni-mapa-podivejte-se-kde-dostavaji-ridici-v-praze-nejvic-pokut-za-rychlost--1426283)
  * [Kde, kdy a proč se v Praze odtahuje nejvíce aut? Najděte si svou ulici](http://www.rozhlas.cz/zpravy/data/_zprava/kde-kdy-a-proc-se-v-praze-odtahuje-nejvice-aut-najdete-si-svou-ulici--1423801)
  * [Rychlostní pasti v Brně: Nejvíce pokut padlo v Líšni](http://www.rozhlas.cz/zpravy/data/_zprava/rychlostni-pasti-v-brne-nejvice-pokut-padlo-v-lisni--1426280)
  * [Mapa odtahů v Brně: Objevte nejrizikovější místa](http://www.rozhlas.cz/zpravy/data/_zprava/mapa-odtahu-v-brne-objevte-nejrizikovejsi-mista--1424350)
  * [Odtahy v Teplicích: Auto vám nezmizí přes noc](http://www.rozhlas.cz/zpravy/data/_zprava/odtahy-v-teplicich-auto-vam-nezmizi-pres-noc--1424353)

Data jsou v adresáři `/data` ve formátu csv, jsou oddělená pro každé město a rozdělena na přestupkovou agendu a odtahy. Označení typu přestupku je zadáváno ručně a obsahuje řadu překlepů, před analýzou je tedy třeba sloučit různé varianty zápisu téhož přestupku.


> Projekt [datové rubriky Českého rozhlasu](http://www.rozhlas.cz/zpravy/data/). Uvolněno pod licencí [CC BY-NC-SA 3.0 CZ](http://creativecommons.org/licenses/by-nc-sa/3.0/cz/), tedy uveďte autora, nevyužívejte dílo ani přidružená data komerčně a zachovejte licenci.

## Instalace vizualizace

    npm install -g LiveScript@1.2.0
    npm install
    slake deploy

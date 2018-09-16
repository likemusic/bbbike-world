cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_MAPSFORGE_VERSION by http://mapsforge.org


Please read the OSM wiki how to install the maps on your Android device:

  https://wiki.openstreetmap.org/wiki/Mapsforge
  https://github.com/mapsforge/mapsforge/


Diese Mapsforge Karte wurde erzeugt am: $date
Mapsforge Kartenstil: $map_style
GPS Rechteck Koordinaten (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name des Gebietes: $city


Spenden sind willkommen! 
Du kannst uns via PayPal oder Banküberweisung unterstützen

  https://extract.bbbike.org/community.de.html

Deine Unterstützung hält den BBBike Extract Service am Laufen!
Bitte spende mit PayPal oder Banküberweisung. Wir brauche 10 Euro am Tag bzw.
300 Euro im Monat um die Serverkosten zu decken. Vielen Dank!

Danke, Wolfram Schneider

--
BBBike professional plans: https://extract.bbbike.org/support.html
Planet.osm extracts: https://extract.bbbike.org
BBBike Map Compare: https://mc.bbbike.org
EOF

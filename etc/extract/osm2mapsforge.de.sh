cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, http://extract.bbbike.org
$BBBIKE_EXTRACT_MAPSFORGE_VERSION by http://mapsforge.org


Please read the OSM wiki how to install the maps on your Android device:

  https://wiki.openstreetmap.org/wiki/Mapsforge
  https://github.com/mapsforge/mapsforge/


Diese Mapsforge Karte wurde erzeugt am: $date
Mapsforge Kartenstil: $map_style
GPS Rechteck Koordinaten (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name des Gebietes: $city


Spenden sind willkommen! Du kannst uns via PayPal, Flattr oder Bankueberweisung
unterstuetzen: http://www.bbbike.org/community.de.html

Danke, Wolfram Schneider

--
Dein Fahrrad-Routenplaner: http://www.BBBike.org
BBBike Map Compare: http://bbbike.org/mc
EOF

cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_SHAPE_VERSION by Geofabrik, https://geofabrik.de


Please read the OSM wiki how to use shape files.

  https://wiki.openstreetmap.org/wiki/Shapefiles


Dieses Esri shapefile wurde erzeugt am: $date
GPS Rechteck Koordinaten (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name des Gebietes: $city

Spenden sind willkommen! Du kannst uns via PayPal oder Bankueberweisung
unterstuetzen: https://www.bbbike.org/community.de.html

Danke, Wolfram Schneider

--
Dein Fahrrad-Routenplaner: https://www.bbbike.org
BBBike Map Compare: https://mc.bbbike.org
EOF


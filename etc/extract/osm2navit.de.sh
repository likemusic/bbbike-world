cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, http://extract.bbbike.org
$BBBIKE_EXTRACT_NAVIT_VERSION by http://www.navit-project.org


Please read the Navit homepage and the wiki how to use Navit files:

  http://wiki.navit-project.org


Diese Navit Karte wurde erzeugt am: $date
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

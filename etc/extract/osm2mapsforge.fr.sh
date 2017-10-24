cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, https://extract.bbbike.org
$BBBIKE_EXTRACT_MAPSFORGE_VERSION by http://mapsforge.org


Please read the OSM wiki how to install the maps on your Android device:

  https://wiki.openstreetmap.org/wiki/Mapsforge
  https://github.com/mapsforge/mapsforge/


This Mapsforge map was created on: $date
Mapsforge map style: $map_style
GPS rectangle coordinates (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name of area: $city

We appreciate any feedback, suggestions and a donation! You can support us via
PayPal or bank wire transfer: https://www.BBBike.org/community.html

thanks, Wolfram Schneider

--
Your Cycle Route Planner: https://www.BBBike.org
BBBike Map Compare: https://bbbike.org/mc
EOF

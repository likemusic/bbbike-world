cat << EOF
Map data (c) OpenStreetMap contributors, https://www.openstreetmap.org
Extracts created by BBBike, http://BBBike.org
$BBBIKE_EXTRACT_MAPSME_VERSION by https://github.com/mapsme/omim


Please read the maps.me homepage how to use mwm files:

  https://maps.me/en/home
  https://maps.me/en/help
  https://wiki.openstreetmap.org/wiki/Maps.Me

Note: Routing in this extract is not support yet! Sorry.


This maps.me file was created on: $date
GPS rectangle coordinates (lng,lat): $BBBIKE_EXTRACT_COORDS
Script URL: $BBBIKE_EXTRACT_URL
Name of area: $city

We appreciate any feedback, suggestions and a donation! You can support us via
PayPal, Flattr or bank wire transfer: http://www.BBBike.org/community.html

thanks, Wolfram Schneider

--
http://www.BBBike.org - Your Cycle Route Planner
EOF
mkdir -p tmp/dateline-planet
osmconvert-wrapper -o tmp/dateline-planet/planet-latest-nometa-osmconvert-fiji.osm.pbf -B=world/etc/dateline-planet/fiji.poly --drop-author --drop-version --out-pbf ../osm/download/planet-latest-nometa.osm.pbf
osmconvert-wrapper -o tmp/dateline-planet/planet-latest-nometa-osmconvert-left-179.osm.pbf -B=world/etc/dateline-planet/left-179.poly --drop-author --drop-version --out-pbf ../osm/download/planet-latest-nometa.osm.pbf
osmconvert-wrapper -o tmp/dateline-planet/planet-latest-nometa-osmconvert-left-180.osm.pbf -B=world/etc/dateline-planet/left-180.poly --drop-author --drop-version --out-pbf ../osm/download/planet-latest-nometa.osm.pbf
osmconvert-wrapper -o tmp/dateline-planet/planet-latest-nometa-osmconvert-left-right-180.osm.pbf -B=world/etc/dateline-planet/left-right-180.poly --drop-author --drop-version --out-pbf ../osm/download/planet-latest-nometa.osm.pbf
osmconvert-wrapper -o tmp/dateline-planet/planet-latest-nometa-osmconvert-right-179.osm.pbf -B=world/etc/dateline-planet/right-179.poly --drop-author --drop-version --out-pbf ../osm/download/planet-latest-nometa.osm.pbf
osmconvert-wrapper -o tmp/dateline-planet/planet-latest-nometa-osmconvert-right-180.osm.pbf -B=world/etc/dateline-planet/right-180.poly --drop-author --drop-version --out-pbf ../osm/download/planet-latest-nometa.osm.pbf
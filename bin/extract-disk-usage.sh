#!/bin/sh
# Copyright (c) 2012-2013 Wolfram Schneider, http://bbbike.org
#
# osm2garmin - convert a osm/pbf file to garmin
#

PATH=/usr/local/bin:/bin:/bin:/usr/bin; export PATH
: ${BBBIKE_EXTRACT_LANG=en}
: ${BBBIKE_OPT_DIR="/var/lib/bbbike/opt"}
: ${BBBIKE_MKGMAP_VERSION="mkgmap"}
: ${BBBIKE_SPLITTER_VERSION="splitter"}

set -e

usage () {
   echo "$@"
   echo "usage file [ osm | cycle | leisure | bbbike ] [ title ]"
   exit 1
}

error () {
    message="$@"

    echo "$message"
    echo "file: $file"
    cat $logfile
    exit 1
}

file=$1
city=$3

test -z "$file" && usage

# absolute file path
case $file in /*) ;; *) file=$(pwd)/$file ;; esac

text2html=$(dirname $0)/text2html.sh
case $text2html in /*) ;; *) text2html=$(pwd)/$text2html ;; esac

test -e "$file" || usage "file $file does not exists"
: ${osm_checksum=`dirname $0`/osm-checksum}

template=$(dirname $0)/../etc/extract/$(basename $0).$BBBIKE_EXTRACT_LANG.sh
case $template in /*) ;; *) template=$(pwd)/$template ;; esac

test -z "$ext" && ext=${2-"osm"}
: ${debug=false}

size=$(du -ks -L "$file" | awk '{ print $1}')
: ${java_heap=3G}
if [ $size -gt 250000 ]; then
   java_heap=6G
elif [ $size -gt 150000 ]; then
   java_heap=5G
elif [ $size -gt 100000 ]; then
   java_heap=4G
fi

if [ $size -lt 100 ]; then
  splitter_resolution=18
elif [ $size -lt 2000 ]; then
  splitter_resolution=16
else
  splitter_resolution=13
fi

#case $ext in *leisure* ) java_heap=3500M ;; esac

pwd=$(pwd)
license="license.txt"
copyright="OpenStreetMap.org"
java_opt=-Xmx${java_heap}
mkgmap_map_style="osm"
: ${max_jobs="--max-jobs=2"}

etc_dir=`dirname $0`/../etc/mkgmap
# absolute path
case $etc_dir in /* ) ;; *) etc_dir=$pwd/$etc_dir ;; esac

case $ext in
   cycle | garmin-cycle.zip )
	ext=garmin-cycle.zip
	mkgmap_map=--style-file=$etc_dir/cyclemap
	mkgmap_map_style=cyclemap
	mkgmap_map_type=$etc_dir/cyclemap.TYP
	;;

   leisure | freizeit | garmin-freizeit.zip | garmin-leisure.zip )
	ext=garmin-leisure.zip
	mkgmap_map=--style-file=$etc_dir/freizeit
	mkgmap_map_style=freizeit
	mkgmap_map_type=$etc_dir/freizeit.TYP
	;;
        
   bbbike | garmin-bbbike.zip )
	ext=garmin-bbbike.zip
	mkgmap_map=--style-file=$etc_dir/../../../misc/mkgmap/srt-style
	mkgmap_map_style=bbbike
	mkgmap_map_type=$etc_dir/../../../misc/mkgmap/typ/M000002a.TYP
        ;;

   osm | garmin-osm.zip )
	ext=garmin-osm.zip
	;;

   *) usage ;;
esac

garmin_product_id=1
case $ext in
   *cycle* )   garmin_product_id=2 ;;
   *leisure* ) garmin_product_id=3 ;;
   *bbbike* )  garmin_product_id=4 ;;
esac

: ${MD5=`which md5 md5sum false | head -1`}
garmin_family_id=$(basename $file | perl -npe 's/\.osm(\.pbf|\.gz|\.bz2)?$//')
garmin_family_id=$(echo $garmin_family_id $ext | $MD5 | perl -ne 's/[a-f]//g; print /^(\d{4})/ ? $1 : "4444"')
mkgmap_opt="--keep-going --family-id=$garmin_family_id --product-id=$garmin_product_id --remove-short-arcs --route --add-pois-to-areas --copyright-message="$copyright" --license-file=$license --index --make-all-cycleways"

if [ -n "$mkgmap_map_type" ]; then
   test -e "$mkgmap_map_type" || usage "cannot find $mkgmap_map_type file"
fi

tmpdir=`mktemp -d ${TMPDIR-"/tmpfs"}/garmin.$(basename $ext .zip).XXXXXXXXXXX`

# cleanup after signal, but show errors first
trap '( sleep 1; rm -rf $tmpdir ) &' 1 2 15

split_dir=$tmpdir/split
mkdir -p $split_dir

garmin=`basename $file | perl -npe 's/\.osm(\.pbf|\.gz|\.bz2)?$//'`
garmin_dir=$tmpdir/$garmin-`basename $ext .zip`
mkdir -p $garmin_dir

logfile=$garmin_dir/logfile.txt
touch $logfile

# mkgmap bug
if [ ! -s $file ]; then
    : #error "file size is zero, give up!"
fi

#mapid=63240001
mapid=${garmin_family_id}0001
      
#if [ $size -lt 10000 ]; then
#   echo "PBF file size $size KB, run without splitter" > $logfile
#   ln -s $file $split_dir/63240001.osm.pbf
#else
#fi
echo ">>> Run splitter" > $logfile
(set -x; java $java_opt -jar $BBBIKE_OPT_DIR/$BBBIKE_SPLITTER_VERSION/splitter.jar --resolution=$splitter_resolution --max-nodes=1000000 --mapid="$mapid" --output-dir=$split_dir $file ) >> $logfile 2>&1 || error

if [ $(ls $split_dir/*.pbf 2>/dev/null | wc -l) -eq 0 ]; then
    echo "Warning: splitter didn't created a file: $file"
    if [ $size -le 1000 ]; then
	cp -f $file $split_dir/$mapid.osm.pbf
    else
	echo "Argh, $file with size $size to big for single run"
    fi
fi

date=$(date -u)
date_short=$(date -u '+%d-%b-%Y %H:%M:%S')
if [ -z "$city" ]; then
   description="$garmin, BBBike.org $date_short"
else
   description="$city, BBBike.org $date_short"
fi

# the limit for description field is 50 bytes
coords=$(echo $garmin | perl -npe 's,planet_,,; s/_/ /g')
description=$(echo $description | perl -npe '$_=substr($_,0,50)')

set_typ=$(dirname $0)/freizeitkarte-set-typ.pl
case $set_typ in /*) ;; *) set_typ=$(pwd)/$set_typ ;; esac

cd $garmin_dir
echo "Map data (c) OpenStreetMap.org contributors" > $license


BBBIKE_EXTRACT_COORDS=$BBBIKE_EXTRACT_COORDS BBBIKE_EXTRACT_URL=$BBBIKE_EXTRACT_URL \
  date=$date city=$city mkgmap_map_style=$mkgmap_map_style sh $template > README.txt

$text2html < README.txt > README.html

if [ -n "$mkgmap_map_type" ]; then
   cp $mkgmap_map_type map.TYP
   mkgmap_map_type=map.TYP
   $set_typ $garmin_family_id $garmin_product_id $mkgmap_map_type >> $logfile 2>&1 
fi

# --mapname="$mapid" 
echo ">>> Run mkgmap, map style: $mkgmap_map_style" >> $logfile
( set -x 
  java $java_opt -jar $BBBIKE_OPT_DIR/$BBBIKE_MKGMAP_VERSION/mkgmap.jar $max_jobs $mkgmap_opt $mkgmap_map \
    --gmapsupp --description="$description" --family-name="$coords style=$mkgmap_map_style" $split_dir/*.pbf $mkgmap_map_type ) >> $logfile 2>&1  || error

#echo ">>> Run mkgmap, create gmapsupp file" >> $logfile
#( set -x
#  java $java_opt -jar $BBBIKE_OPT_DIR/mkgmap/mkgmap.jar --gmapsupp [0-9][0-9]*.img ) >> $logfile 2>&1  || error

if egrep -ql '^java\.lang\.' $logfile; then
    error
fi

rm -f $license
rm -f map.TYP

# gmapsupp.img cleanup
rm -rf osmmap.tdb osmmap.img osmmap.mdx osmmap_mdr.img [0-9][0-9]*.img ovm_*.img

case $BBBIKE_EXTRACT_LANG in
  en ) ext2=$ext ;;
   * ) ext2=$(echo $ext | perl -npe "s/\.zip\$/.${BBBIKE_EXTRACT_LANG}.zip/") ;;
esac

cd ..
garmin_zip=`dirname $file`/$garmin.osm.$ext2
zip -q -r - -- `basename $garmin_dir` | \
  ( cd $pwd;
    cat > $garmin_zip.tmp && mv $garmin_zip.tmp $garmin_zip
    $osm_checksum $garmin_zip
  )

$debug || rm -rf $tmpdir

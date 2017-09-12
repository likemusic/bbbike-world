#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, https://bbbike.org

use Test::More;
use lib qw(world/lib);
use Extract::TileSize;

use strict;
use warnings;

# reset default debug value
$Extract::TileSize::debug     = 0;
$Extract::TileSize::use_cache = 0;

plan tests => 113;

my $tile = new Extract::TileSize( 'debug' => -1 );

ok(1);

is( $tile->total, 64800 );

# count with 100% size of fractal tiles
is( $tile->area_size( 0,    0,    1,    1 ),   1 );
is( $tile->area_size( 0.2,  0.2,  1,    1 ),   1 );
is( $tile->area_size( 0.2,  0.2,  0.8,  0.8 ), 1 );
is( $tile->area_size( -180, -90,  -179, -89 ), 1 );
is( $tile->area_size( 0,    0,    2,    2 ),   4 );
is( $tile->area_size( -2,   -2,   0,    0 ),   4 );
is( $tile->area_size( -1,   -1,   1,    1 ),   4 );
is( $tile->area_size( -1.5, -1.5, 1.5,  1.5 ), 16 );
is( $tile->area_size( -1.5, -1.5, 1,    1 ),   9 );
is( $tile->area_size( 0,    50,   15,   54 ),  60 );
is( $tile->area_size( 0.1,  0,    3,    3 ),   9 );
is( $tile->area_size( 0.1,  0.1,  2.9,  2.9 ), 9 );

is( $tile->area_size( 0.1, 0.1, 2.9, 2.9, Extract::TileSize::FRACTAL_100 ), 9 );
is( $tile->area_size( -2.9, 0.1, -0.1, 2.9, Extract::TileSize::FRACTAL_100 ),
    9 );
is( $tile->area_size( -2.9, -2.9, -0.1, -0.1, Extract::TileSize::FRACTAL_100 ),
    9 );
is( $tile->area_size( -1, -1, -0, -0, Extract::TileSize::FRACTAL_100 ), 1 );
is( $tile->area_size( 0,  50, 15, 54, Extract::TileSize::FRACTAL_100 ), 60 );

# dummy
is( $tile->area_size( 0,    0,   0,    0 ),   0 );
is( $tile->area_size( -180, -90, -180, -90 ), 0 );

# count with 50% size of fractal tiles
is( $tile->area_size( 0.1, 0.1, 2.9, 2.9, Extract::TileSize::FRACTAL_50 ), 5 );
is( $tile->area_size( 0,   50,  15,  54,  Extract::TileSize::FRACTAL_50 ), 60 );
is( $tile->area_size( 0.5, 50,  15,  54,  Extract::TileSize::FRACTAL_50 ), 58 );
is( $tile->area_size( 0.5, 50, 15.5, 54, Extract::TileSize::FRACTAL_50 ), 60 );
is( $tile->area_size( 0.5, 49.5, 15.5, 54, Extract::TileSize::FRACTAL_50 ),
    68 );
is( $tile->area_size( 0.5, 49.5, 16.5, 54.1, Extract::TileSize::FRACTAL_50 ),
    81 );

# count with real size of fractal tiles
is(
    int(
        $tile->area_size( 0.1, 0.1, 2.9, 2.9, Extract::TileSize::FRACTAL_REAL )
          * 10
      ) / 10,
    7.8
);
is(
    int(
        $tile->area_size( 0.8, 0.8, 2.2, 2.2, Extract::TileSize::FRACTAL_REAL )
          * 10
      ) / 10,
    1.9
);
is(
    int(
        $tile->area_size( 1.0, 1.0, 2, 2, Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    1
);
is(
    int(
        $tile->area_size( 10.1, 50.1, 12.9, 52.9,
            Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    7.8
);
is(
    int(
        $tile->area_size( 15.1, 55.1, 17.9, 57.5,
            Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    6.7
);
is(
    int(
        $tile->area_size( 1.1, 1.0, 2, 2, Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    0.9
);
is(
    int(
        $tile->area_size( 1.5, 1.0, 2, 2, Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    0.5
);
is(
    int(
        $tile->area_size( 1.5, 1.5, 2, 2, Extract::TileSize::FRACTAL_REAL ) *
          100 + 0.5
      ) / 100,
    0.25
);

# date border, Fiji island
cmp_ok( $tile->area_size( 178.9, -18.3, -166.9, -8.4, 2 ), ">", 0 );
cmp_ok(
    $tile->area_size(
        +172.68, -18.53, -173.12, -8.64, Extract::TileSize::FRACTAL_REAL
    ),
    ">", 100
);
cmp_ok(
    $tile->area_size( 179.9, -18, +180, +18, Extract::TileSize::FRACTAL_100 ),
    "==", 36 );
cmp_ok( $tile->area_size( 179, 0, 180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( 179, 0, -180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( -180, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( +180, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( +179, -1, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 4 );

# illegal query
cmp_ok( $tile->area_size( +179, 0, +178, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( -178, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( -179.5, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( +179, 0, +180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );

cmp_ok( $tile->area_size( -180, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( -179, 0, +180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );

cmp_ok( $tile->area_size( -180, 0, +180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( +180, 0, +180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 0 );

cmp_ok( $tile->area_size( 0, 89, 1, 91, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 0, 91, 1, 92, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 0, -91, 1, -90, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 0, -89, 1, -92, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );

cmp_ok( $tile->area_size( -90.1, 0, 81, -89, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 359, 0, 360, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( 359, 0, 361, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 369, 0, 391, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 512, 512, 512, 512, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok(
    $tile->area_size( -512, -512, -512, -512, Extract::TileSize::FRACTAL_100 ),
    "==", -1
);

# fixable
cmp_ok( $tile->area_size( -280, 0, -279, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( 280, 0, 281, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );

# test with real planet.osm data
$tile = new Extract::TileSize( 'database' => "world/etc/tile/pbf.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 64660 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 366224 );
is( $tile->total_tiles, 15924 );
is( $tile->total,       28223424 );

$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/garmin-osm.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 39297 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 254574 );
is( $tile->total_tiles, 15133 );
is( $tile->total,       19701265 );

$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/garmin-onroad.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 3955 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 69433 );
is( $tile->total_tiles, 7999 );
is( $tile->total,       4718827 );

$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/mapsforge-osm.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 50040 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 286785 );
is( $tile->total_tiles, 15924 );
is( $tile->total,       23244763 );

$tile = new Extract::TileSize( 'database' => "world/etc/tile/navit.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 55476 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 309905 );
is( $tile->total_tiles, 15133 );
is( $tile->total,       23098429 );

$tile = new Extract::TileSize( 'database' => "world/etc/tile/obf.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 156534 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 703830 );
is( $tile->total_tiles, 15924 );
is( $tile->total,       47313649 );

$tile = new Extract::TileSize( 'database' => "world/etc/tile/osm.gz.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 135572 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 804884 );
is( $tile->total_tiles, 15924 );
is( $tile->total,       62316009 );

$tile = new Extract::TileSize( 'database' => "world/etc/tile/shp.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 290719 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 1614345 );
is( $tile->total_tiles, 15916 );
is( $tile->total,       116927944 );

# placeholder for osm csv format
#$tile =
#  new Extract::TileSize( 'database' => "world/etc/tile/shp.zip.csv" );
#is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 194908 );

my $size = Extract::TileSize::FRACTAL_REAL;

# elevation test
$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/srtm-europe-pbf.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 396 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 82392 );
$tile = new Extract::TileSize(
    'database' => "world/etc/tile/srtm-europe-obf.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 554 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 159617 );

$tile = new Extract::TileSize(
    'database' => "world/etc/tile/srtm-europe-garmin-srtm.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 515 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 115754 );

####################################################################
# elevation test with planet-srtm.pbf
#
$tile = new Extract::TileSize( 'database' => "world/etc/tile/srtm-pbf.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 244 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 65263 );
is( $tile->total_tiles, 13418 );
is( $tile->total,       14387080 );

$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/srtm-obf.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 342 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 216920 );
is( $tile->total_tiles, 13418 );
is( $tile->total,       39058946 );

$tile = new Extract::TileSize(
    'database' => "world/etc/tile/srtm-garmin-srtm.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 317 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 153152 );
is( $tile->total_tiles, 13418 );
is( $tile->total,       28491956 );

__END__

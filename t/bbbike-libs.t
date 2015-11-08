#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Test::More;
use Data::Dumper;

use lib qw(world/lib);
use BBBike::Ads;
use BBBike::Analytics;
use BBBike::Elevation;
use BBBike::Googlemap;
use Extract::Locale;
use BBBike::Test;
use BBBike::WorldDB;

use strict;
use warnings;

# testing
$Extract::Locale::option->{'message_path'} = "world/etc/extract";

my $debug     = 1;
my $Ads       = new BBBike::Ads( 'debug' => $debug );
my $Analytics = new BBBike::Analytics( 'debug' => $debug );
my $Elevation = new BBBike::Elevation( 'debug' => $debug );
my $Googlemap = new BBBike::Googlemap( 'debug' => $debug );
my $Locale    = new Extract::Locale( 'debug' => $debug );
my $Test      = new BBBike::Test( 'debug' => $debug );
my $WorldDB   = new BBBike::WorldDB( 'debug' => $debug );

plan tests => 7;

isnt( $Ads,       undef, "BBBike::Ads" );
isnt( $Analytics, undef, "BBBike::Analytics" );
isnt( $Elevation, undef, "BBBike::Elevation" );
isnt( $Googlemap, undef, "BBBike::Googlemap" );
isnt( $Locale,    undef, "Extract::Locale" );
isnt( $Test,      undef, "BBBike::Test" );
isnt( $WorldDB,   undef, "BBBike::WorldDB" );

__END__

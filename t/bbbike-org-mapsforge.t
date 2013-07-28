#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

BEGIN { }

use FindBin;
use lib ( "$FindBin::RealBin/..", "$FindBin::RealBin/../lib",
    "$FindBin::RealBin", );

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Digest::MD5 qw(md5_hex);
use File::stat;

use strict;
use warnings;

plan tests => 4;

my $pbf_file = 'world/t/data-osm/tmp/Cusco.osm.pbf';

if ( !-f $pbf_file ) {
    system(qw(ln -sf ../Cusco.osm.pbf world/t/data-osm/tmp));
    die "symlink failed: $!\n" if $?;
}

my $pbf_md5 = "6dc9df64ddc42347bbb70bc134b4feda";

# min size of zip file
my $min_size = 180_000;

sub md5_file {
    my $file = shift;
    my $fh = new IO::File $file, "r";
    die "open file $file: $!\n" if !defined $fh;

    my $data;
    while (<$fh>) {
        $data .= $_;
    }

    $fh->close;

    my $md5 = md5_hex($data);
    return $md5;
}

######################################################################
is( $pbf_md5, md5_file($pbf_file), "md5 checksum matched" );

my $tempfile = File::Temp->new( SUFFIX => ".osm" );
my $prefix = $pbf_file;
$prefix =~ s/\.pbf$//;
my $st = 0;

system(qq[world/bin/pbf2osm --mapsforge-osm $pbf_file]);
is( $?, 0, "pbf2osm --mapsforge-osm converter" );
my $out = "$prefix.mapsforge-osm.zip";
$st = stat($out) or die "Cannot stat $out\n";

system(qq[unzip -t $out]);
is( $?, 0, "valid zip file" );

my $size = $st->size;
cmp_ok( $size, '>', $min_size, "$out: $size > $min_size" );

__END__

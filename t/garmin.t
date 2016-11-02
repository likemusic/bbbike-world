#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, http://bbbike.org

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Digest::MD5 qw(md5_hex);
use File::stat;

use lib qw(./world/lib ../lib);
use Test::More::UTF8;
use Extract::Test::Archive;

use strict;
use warnings;

my @garmin_styles = qw/osm/;
push @garmin_styles, qw/leisure cycle/
  if !$ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_LONG};
push @garmin_styles, qw/bbbike openfietslite onroad/ if $ENV{BBBIKE_TEST_LONG};

if ( $ENV{BBBIKE_TEST_LONG} && $0 =~ /garmin-ascii.t$/ ) {
    @garmin_styles =
      qw/bbbike-ascii openfietslite-ascii cycle-ascii leisure-ascii osm-ascii onroad-ascii oseam oseam-ascii/;
}

#die join " ", @garmin_styles,;

my $pbf_file = 'world/t/data-osm/tmp/Cusco.osm.pbf';

if ( !-f $pbf_file ) {
    system(qw(ln -sf ../Cusco.osm.pbf world/t/data-osm/tmp)) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "525744cddeef091874eaddc05f10f19b";

# min size of garmin zip file
my $min_size = 240_000;

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
sub convert_format {
    my $lang        = shift;
    my $format      = shift;
    my $format_name = shift;

    my $timeout  = 30;
    my $counter  = 0;
    my $tempfile = File::Temp->new( SUFFIX => ".osm" );
    my $st       = 0;

    my $test = Extract::Test::Archive->new(
        'lang'        => $lang,
        'pbf_file'    => $pbf_file,
        'format'      => $format,
        'format_name' => $format_name
    );
    my $city = $test->init_cusco;

    # known styles
    foreach my $style (@garmin_styles) {
        my $out = $test->out($style);
        unlink $out;

        diag "garmin style=$style, lang=$lang";

        system(qq[world/bin/pbf2osm --garmin-$style $pbf_file $city]);
        is( $?, 0, "pbf2osm --garmin-$style converter" );

        system(qq[unzip -tqq $out]);
        is( $?, 0, "valid zip file" );
        $st = stat($out);
        my $size = $st->size;
        my $min_size_style = $style =~ /^onroad/ ? $min_size / 3 : $min_size;
        cmp_ok( $size, '>', $min_size_style, "$out: $size > $min_size" );

        system(qq[world/bin/extract-disk-usage.sh $out > $tempfile]);
        is( $?, 0, "extract disk usage check" );

        my $image_size = `cat $tempfile` * 1024;
        cmp_ok( $image_size, '>', $size, "image size: $image_size > $size" );

        $counter += 5;
        $test->validate( 'style' => $style );
    }

    return $counter + $test->counter;
}

#######################################################
#
is( $pbf_md5, md5_file($pbf_file), "md5 checksum matched" );

my $counter = 0;
my @lang = ( "en", "de" );

if ( !$ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_LONG} ) {
    push @lang, ( "fr", "es", "ru", "" );
}

foreach my $lang (@lang) {
    $counter += &convert_format( $lang, 'garmin', 'Garmin' );
}

plan tests => 1 + $counter;
__END__

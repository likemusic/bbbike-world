#!/usr/bin/perl
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# livesearch.cgi - bbbike.org live routing search

use CGI qw/-utf-8 unescape/;
use URI;
use URI::QueryParam;

use IO::File;
use JSON;
use Data::Dumper;

use strict;
use warnings;

my $logfile                   = '/var/log/lighttpd/bbbike.error.log';
my $max                       = 50;
my $only_production_statistic = 1;
my $debug                     = 1;

binmode \*STDOUT, ":raw";
my $q = new CGI;

sub is_mobile {
    my $q = shift;

    if (   $q->param('skin') && $q->param('skin') =~ m,^(m|mobile)$,
        || $q->virtual_host() =~ /^m\.|^mobile\.|^dev2/ )
    {
        return 1;
    }
    else {
        return 0;
    }
}

sub date_alias {
    my $date = shift;

    if ( $date eq 'today' ) {
        return substr( localtime(time), 4, 6 );
    }
    elsif ( $date eq 'yesterday' ) {
        return substr( localtime( time - 24 * 60 * 60 ), 4, 6 );
    }
    elsif ( $date =~ /^yesterday(\d)$/ ) {
        return substr( localtime( time - ( 24 * $1 ) * 60 * 60 ), 4, 6 );
    }
    else {
        return $date;
    }
}

sub logfiles {
    my $file    = shift;
    my @numbers = @_;

    my @files;
    for my $num (@numbers) {
        push @files, "$file.$num.gz";
    }
    return @files;
}

#
# estimate the usage for a 24 hour period. Based on the google analytics
# usage statistics for April 2011
#
sub estimated_daily_usage {
    my $counter = shift;

    $counter = 1 if $counter <= 0;

    # hour -> percentage
    my $hourly_usage = {
        0  => 2.44,
        1  => 1.21,
        2  => 0.65,
        3  => 0.36,
        4  => 0.36,
        5  => 0.35,
        6  => 0.94,
        7  => 2.03,
        8  => 4.13,
        9  => 5.76,
        10 => 6.74,
        11 => 7.75,
        12 => 7.12,
        13 => 7.06,
        14 => 6.47,
        15 => 5.09,
        16 => 4.95,
        17 => 4.72,
        18 => 4.93,
        19 => 5.70,
        20 => 5.80,
        21 => 6.43,
        22 => 5.28,
        23 => 3.74,
    };

    my ( $hour, $min ) = ( localtime(time) )[ 2, 3 ];
    my $now = 0;

    foreach my $key ( keys %$hourly_usage ) {
        if ( $key < $hour ) {
            $now += $hourly_usage->{$key};
        }
        elsif ( $key == $hour ) {
            $now += $hourly_usage->{$key} * $min / 60;
        }
    }

    return int( $counter * 100 / $now );
}

sub is_production {
    my $q = shift;

    return 1 if -e "/tmp/is_production";
    return $q->virtual_host() =~ /^www\.bbbike\.org$/i ? 1 : 0;
}

# extract URLs from web server error log
sub extract_route {
    my $file  = shift;
    my $max   = shift;
    my $devel = shift;
    my $date  = shift;

    my $host = $devel ? '(dev|devel|www)' : 'www';

    my @data;
    my %hash;
    my @files;
    push @files, $file;
    push @files, &logfiles( $file, 1, 2 );
    push @files, &logfiles( $file, 3, 4 ) if $max > 50;
    push @files, &logfiles( $file, 5, 6, 7 ) if $max > 100;
    push @files, &logfiles( $file, 8 .. 20 ) if $max > 500;

    if ($date) {
        $date = &date_alias($date);

        eval { "foo" =~ /$date/ };
        if ($@) {
            warn "date failed: '$date'\n";
            $date = "";
        }
    }

    foreach my $file ( reverse @files ) {
        next if !-f $file;

        my $fh;
        warn "Open $file ...\n" if $debug >= 2;
        if ( $file =~ /\.gz$/ ) {
            open( $fh, "gzip -dc $file |" ) or die "open $file: $!\n";
        }
        else {
            open( $fh, $file ) or die "open $file: $!\n";
        }
        binmode $fh, ":raw";

        while (<$fh>) {
            next
              if !(
                         / slippymap\.cgi: /
                      || m, (bbbike|[A-Z][a-zA-Z]+)\.cgi: http://,
              );

            next
              if $only_production_statistic
                  && !
m, (slippymap|bbbike|[A-Z][a-zA-Z]+)\.cgi: http://$host.bbbike.org/,i;

            next if !/coords/;
            next if $date && !/$date/;
            next if /[;&]cache=1/;

            my @list = split;
            my $url  = pop(@list);

            next if scalar(@data) > 20_000;    # keep memory usage low
            push( @data, $url );

        }
        close $fh;
    }

    return reverse @data;
}

sub footer {
    my $q = new CGI;

    my $data = "";
    $q->delete('date');

    foreach my $number ( 10, 25, 50, 100, 250, 500, 1000 ) {
        if ( $number == $max ) {
            $data .= " | $number";
        }
        else {
            $q->param( "max", $number );
            $data .=
                qq, | <a title="max. $number routes" href=",
              . $q->url( -relative => 1, -query => 1 )
              . qq{">$number</a>\n};
        }
    }

    # date links: before yesterday | yesterday | today
    $q->param( "max",  "700" );
    $q->param( "date", "yesterday2" );
    $data .=
        qq{ | <a href="}
      . $q->url( -relative => 1, -query => 1 )
      . qq{">before yesterday</a>\n};

    $q->param( "max",  "700" );
    $q->param( "date", "yesterday" );
    $data .=
        qq{ | <a href="}
      . $q->url( -relative => 1, -query => 1 )
      . qq{">yesterday</a>\n};

    $q->param( "date", "today" );
    $data .=
        qq{ | <a href="}
      . $q->url( -relative => 1, -query => 1 )
      . qq{">today</a>\n};

    return <<EOF;
<div id="footer">
<div id="footer_top">
<a href="../">home</a> |
<a href="../cgi/area.cgi">covered area</a>
$data
</div>
</div>

<div id="copyright" style="text-align: center; font-size: x-small; margin-top: 1em;" >
<hr>
(&copy;) 2008-2011 <a href="http://wolfram.schneider.org">Wolfram Schneider</a> &amp; <a href="http://www.rezic.de/eserte">Slaven Rezi&#x107;</a> // <a href="http://www.bbbike.org">http://www.bbbike.org</a> <br >
  Map data by the <a href="http://www.openstreetmap.org/">OpenStreetMap</a> Project // <a href="http://wiki.openstreetmap.org/wiki/OpenStreetMap_License">OpenStreetMap License</a> <br >
<div id="footer_community">
</div>
</div>
EOF
}

sub route_stat {
    my $obj  = shift;
    my $city = shift;

    my ( $average, $median, $max ) = route_stat2( $obj, $city );
    return " average: ${average}km, median: ${median}km, max: ${max}km";
}

sub route_stat2 {
    my $obj  = shift;
    my $name = shift;

    my @routes;

    # one city
    if ($name) {
        @routes = @{ $obj->{$name} };
    }

    # all cities
    else {
        foreach my $key ( keys %$obj ) {
            if ( scalar( @{ $obj->{$key} } ) > 0 ) {
                push @routes, @{ $obj->{$key} };
            }
        }
    }

    my $average = 0;
    my $median  = 0;
    my $max     = 0;

    my @data;
    foreach my $item (@routes) {
        my $route_length = $item->{"route_length"};
        $average += $route_length;
        push @data, $route_length;
        $max = $route_length if $route_length > $max;
    }
    $average = $average / scalar(@routes);

    @data = sort { $a <=> $b } @data;
    my $count = scalar(@data);
    if ( $count % 2 ) {
        $median = $data[ int( $count / 2 ) ];
    }
    else {
        $median =
          ( $data[ int( $count / 2 ) ] + $data[ int( $count / 2 ) - 1 ] ) / 2;
    }

    # round all values to 100 meters
    $median  = int( $median * 10 + 0.5 ) / 10;
    $average = int( $average * 10 + 0.5 ) / 10;
    $max     = int( $max * 10 + 0.5 ) / 10;

    return ( $average, $median, $max );
}

sub html {
    my $q = shift;

    print $q->header( -charset => 'utf-8', -expires => '+30m' );

    my $sensor = is_mobile($q) ? 'true' : 'false';
    print $q->start_html(
        -title => 'BBBike @ World livesearch',
        -head  => $q->meta(
            {
                -http_equiv => 'Content-Type',
                -content    => 'text/html; charset=utf-8'
            }
        ),

        -style => {
            'src' => [
                "../html/devbridge-jquery-autocomplete-1.1.2/styles.css",
                "../html/bbbike.css"
            ]
        },
        -script => [
            {
                -type => 'text/javascript',
                'src' => "../html/jquery-1.4.2.min.js"
            },
            {
                -type => 'text/javascript',
                'src' =>
"../html/devbridge-jquery-autocomplete-1.1.2/jquery.autocomplete-min.js"
            },
            {
                -type => 'text/javascript',
                'src' => "http://www.google.com/jsapi"
            },
            {
                -type => 'text/javascript',
                'src' => "http://maps.google.com/maps/api/js?v=3.3&sensor=false"
            },
            { -type => 'text/javascript', 'src' => "../html/maps3.js" },
            {
                -type => 'text/javascript',
                'src' =>
'http://maps.google.com/maps/api/js?libraries=panoramio&sensor=false'
            }
        ]
    );

    print qq{<div id="routes"></div>\n};
    print qq{<div id="BBBikeGooglemap" style="height:94%">\n};
    print qq{<div id="map"></div>\n};

    print <<EOF;
    <script type="text/javascript">
    //<![CDATA[

    city = "dummy";
    bbbike_maps_init("terrain", [[43, 8],[57, 15]], "en", true, "eu" );
  
    function jumpToCity (coord) {
	var b = coord.split("!");

	var bounds = new google.maps.LatLngBounds;
        for (var i=0; i<b.length; i++) {
	      var c = b[i].split(",");
              bounds.extend(new google.maps.LatLng( c[1], c[0]));
        }
        map.setCenter(bounds.getCenter());
        map.fitBounds(bounds);
	var zoom = map.getZoom();

        // no zoom level higher than 15
         map.setZoom( zoom < 16 ? zoom + 0 : 16);
    } 

    //]]>
    </script>
EOF

    if ( $q->param('max') ) {
        my $m = $q->param('max');
        $max = $m if $m > 0 && $m <= 5_000;
    }

    my $date = $q->param('date') || "";
    my $stat = $q->param('stat') || "name";
    my @d = &extract_route( $logfile, $max, 0, $date );

    print qq{<script type="text/javascript">\n};

    my $city_center;
    my $json = new JSON;
    my $cities;
    my %hash;
    my $counter;
    my $counter2 = 0;
    my @route_display;
    foreach my $url (@d) {
        my $qq = CGI->new($url);
        $counter2++;
        warn $url, "\n" if $debug >= 2;

        next if !$qq->param('driving_time');

        my $coords = $qq->param('coords');
        next if !$coords;
        next if exists $hash{$coords};
        $hash{$coords} = 1;

        last if $counter++ >= $max;

        my @params = qw/city route_length driving_time startname zielname area/;
        push @params,
          qw/pref_cat pref_quality pref_specialvehicle pref_speed pref_ferry pref_unlit/;

        my $opt = { map { $_ => ( $qq->param($_) || "" ) } @params };

        $city_center->{ $opt->{'city'} } = $opt->{'area'};

        my $data = "[";
        foreach my $c ( split /!/, $coords ) {
            $data .= qq{'$c', };
        }
        $data =~ s/, $/]/;

        my $opt_json = $json->encode($opt);
        print qq{plotRoute(map, $opt_json, $data);\n};

        push( @{ $cities->{ $opt->{'city'} } }, $opt ) if $opt->{'city'};
        push @route_display, $url;
    }

    print "/* ", Dumper($cities),      " */\n" if $debug >= 2;
    print "/* ", Dumper($city_center), " */\n" if $debug >= 2;

    my @cities = sort keys %$cities;

    # sort cities by hit counter, not by name
    if ( $stat eq 'hits' ) {
        @cities =
          reverse sort { $#{ $cities->{$a} } <=> $#{ $cities->{$b} } }
          keys %$cities;
    }

    my $d = join(
        "<br/>",
        map {
                qq/<a title="area $_:/
              . &route_stat( $cities, $_ )
              . qq/" href="#" onclick="jumpToCity(\\'/
              . $city_center->{$_}
              . qq/\\')">$_ (/
              . scalar( @{ $cities->{$_} } ) . ")</a>"
          } @cities
    );

#$d.= qq{<p><a href="javascript:flipMarkers(infoMarkers)">flip markers</a></p>};
    $d .= qq{<div id="livestatistic">};
    if (@route_display) {
        my $unique_routes = scalar(@route_display);
        $d .= "<hr />";
        $d .=
qq{Number of unique routes: <span title="total routes: $counter2, cities: }
          . scalar(@cities)
          . qq{">$unique_routes<br />};

        if ( !is_production($q) && $date eq 'today' ) {
            $d .=
                "<p>Estimated usage today: "
              . &estimated_daily_usage($unique_routes) . "/"
              . &estimated_daily_usage($counter2) . "</p>";
        }
        my $qq = CGI->new($q);
        $qq->param( "stat", $stat eq 'hits' ? "name" : "hits" );
        $d .=
            qq{Sort cities by <a href="}
          . $qq->url( -relative => 1, -query => 1 ) . qq{">}
          . ( $stat ne 'hits' ? " hits " : " name " )
          . qq{</a><br />};
        $d .= "<p>Cycle Route Statistic<br/>" . &route_stat($cities) . "</p>";
    }
    else {
        $d .= "No routes found";
    }
    $d .= "</div>";

    print qq{\n\$("div#routes").html('$d');\n\n};

    my $city = $q->param('city') || "";
    if ( $city && exists $city_center->{$city} ) {
        print qq[\njumpToCity('$city_center->{ $city }');\n];
    }

    print qq{\n</script>\n};

    print
qq{<noscript><p>You must enable JavaScript and CSS to run this application!</p>\n</noscript>\n};
    print "</div>\n";
    print &footer;

    print $q->end_html;
}

sub statistic {
    my $q                = shift;
    my $most_used_cities = 10;

    my $max = 700;
    if ( $q->param('max') ) {
        my $m = $q->param('max');
        $max = $m if $m > 0 && $m <= 2_000;
    }

    my $date = $q->param('date') || "today";
    my @d = &extract_route( $logfile, $max, 0, $date );

    my $city_center;
    my $json = new JSON;
    my $cities;
    my %hash;
    my $counter;
    my $counter2 = 0;
    my @route_display;

    foreach my $url (@d) {
        my $qq = CGI->new($url);
        $counter2++;

        next if !$qq->param('driving_time');

        my $coords = $qq->param('coords');
        next if !$coords;
        next if exists $hash{$coords};
        $hash{$coords} = 1;

        last if $counter++ >= $max;

        my @params = qw/city route_length driving_time startname zielname area/;
        push @params,
          qw/pref_cat pref_quality pref_specialvehicle pref_speed pref_ferry pref_unlit/;

        my $opt = { map { $_ => ( $qq->param($_) || "" ) } @params };

        $city_center->{ $opt->{'city'} } = $opt->{'area'};

        push( @{ $cities->{ $opt->{'city'} } }, $opt ) if $opt->{'city'};
        push @route_display, $url;
    }

    print $q->header( -charset => 'utf-8', -expires => '+30m' );
    print $q->start_html( -title => 'BBBike @ World livesearch' );

    my @cities        = sort keys %{$cities};
    my $unique_routes = scalar(@route_display);

    print "<p>City count: ", scalar(@cities),
      ", unique routes: $unique_routes, ", "total routes: $counter2</p>\n";

    if ( $unique_routes > 20 ) {
        print "<p>Estimated usage today: "
          . &estimated_daily_usage($unique_routes) . "/"
          . &estimated_daily_usage($counter2) . "</p>";
    }

    print "<p>Cycle Route Statistic<br/>" . &route_stat($cities) . "</p>\n";

    if ( $most_used_cities && scalar(@cities) > 20 ) {
        print "<hr />\n";
        my @cities2 =
          reverse sort { $#{ $cities->{$a} } <=> $#{ $cities->{$b} } }
          keys %$cities;

        if ( scalar(@cities2) >= $most_used_cities ) {
            @cities2 = @cities2[ 0 .. ( $most_used_cities - 1 ) ];
        }
        print join( "<br/>\n",
            map { $_ . " (" . scalar( @{ $cities->{$_} } ) . ")" } @cities2 );
    }

    print "<hr />\n";
    print join( "<br/>\n",
        map { $_ . " (" . scalar( @{ $cities->{$_} } ) . ")" } @cities );

    # footer
    print "<hr />\n";
    print qq{Copyright (c) 2011 <a href="http://bbbike.org">BBBike.org</a>\n};
}

sub cache {
    my $q = shift;

    my $max = 1000;
    my @d = &extract_route( $logfile, $max, 0, "" );

    my $cities;
    my %hash;
    my %hash2;
    my $counter = 0;
    my @route_display;

    my $limit = $q->param("max") || 50;
    $limit = 20 if $limit < 0 || $limit > 500;

    print $q->header( -charset => 'utf-8', -type => 'text/plain' );

    foreach my $url (@d) {
        $url =~ s/;/&/g;    # bug in URI
        my $u = URI->new($url);

        next if !$u->query_param('driving_time');

        my $coords = $u->query_param('coords');
        next if !$coords;
        next if exists $hash{$coords};
        $hash{$coords} = 1;

        $u->query_param_delete('coords');
        $u->query_param_delete('area');
        $u->query_param_delete('driving_time');

        $u->query_param( 'cache', 1 );

        my $city = $u->query_param("city");

        if ( !exists $hash2{$city} ) {
            $hash2{$city} = 1;

            # pref_cat=N1;pref_quality=Q2;
            $u->query_param( 'pref_cat',     "" );
            $u->query_param( 'pref_quality', "" );
            push @route_display, $u->as_string;

            $u->query_param( 'pref_cat',     "N1" );
            $u->query_param( 'pref_quality', "Q2" );
            push @route_display, $u->as_string;
        }

        last if scalar(@route_display) >= $limit * 2;
    }

    print join "\n", @route_display;
    print "\n";
}

##############################################################################################
#
# main
#

my $ns = $q->param("namespace") || $q->param("ns") || "";
if ( $ns =~ /^stat/ ) {
    &statistic($q);
}
elsif ( $ns =~ /^cache/ ) {
    &cache($q);
}
else {
    &html($q);
}

#
__DATA__


#!/usr/local/bin/perl

use strict;
use CGI qw(:standard);
use CGI::Carp('fatalsToBrowser');

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";

use alDente::Barcode;
use alDente::Barcoding;

print "Content-type: text/html\n\n";

my $dbase = param('database') || 'limstest';
my $host  = param('host');
my $user  = param('user');

my $login_file = "/opt/alDente/versions/production/mysql.login";

print "Connect $user to $dbase @ $host\n\n";

my  $dbc = LampLite::DB->new(
            -dbase              => $dbase,
            -host               => $host,
#            -password           => $pwd,
            -user               => $user,
 #           -session            => $session,
 #           -config             => $Setup,
 #           -session_parameters => $session_params,
 #           -url_parameters     => $url_params,
 #           -login_table        => $login_type,
            -connect            => 1,
            -defer_messages     => 1,
            -sessionless => 1,
            -login_file => $login_file,
        );

print "Connected ? " . $dbc->connected();

# my $barcode = alDente::Barcode->new( -type => $label_name, -dbc=>$dbc);
#
#            $barcode->set_fields(
#                (   'class'   => $prefix,
#                    'id'      => $thisid,
#                    'style'   => "code128",
#                    'barcode' => "$prefix$thisid",
#                    'plateid' => $thislib,
#                    'quad'    => $quad,
###                    'p_code'  => $p_code,
  #                  'p2_code' => $p2_code,
 #                   'b_code'  => $b_code,
 #                   'date'    => $thisday,
 #                   'init'    => $init,
 #                   'label'   => "'$plate_label'"
 #               )
 #           );
#       $barcode->print( -noscale => $noscale, -printer=>$printer);

my $id = 2;

print "Generate barcode...";

# alDente::Barcoding::plate_barcode($dbc, $id);

print "... printed !";

#
# my $barcode = LampLite::Barcode->new(-dbc=>$dbc);
# $barcode->print(-printer=>$printer);
exit;

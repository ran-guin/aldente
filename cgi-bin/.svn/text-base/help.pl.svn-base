#!/usr/local/bin/perl

###############################
# help.pl
###############################

use strict;

use DBI;
use CGI qw(:standard);

#use lib "/usr/local/ulib/prod/perl5";
#use Barcode;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::Errors;
use RGTools::RGIO;
use SDB::CustomSettings;

use alDente::Help;
use alDente::SDB_Defaults;
use alDente::Web;

use RGTools::Barcode;
use SDB::DBIO;
use vars qw($html_header $homelink $URL_address $banner $Settings $dbc);

my $login_name = 'guest';
my $host       = $Configs{SQL_HOST};
my $dbase      = $Configs{DATABASE};
$dbc                  = new SDB::DBIO( -host => $host, -dbase => $dbase, -user => $login_name, -password => $login_pass, -connect => 1 );
$banner               = 0;
$Settings{PAGE_WIDTH} = 700;
my $page;

$homelink = "$URL_address/help.pl?User=Guest";

if ( param('Help') ) {

    #if (1) {
    my $topic = param('Help');

    my $help_topic = param('Help');
    &SDB_help($help_topic);
    print "Help me with topic";
    &leave();
}
elsif ( param('Quick Help') ) {

    #if (1) {
    my $topic = param('Quick Help');

    my $help_topic = param('Quick Help');
    &SDB_help($help_topic);
    print "Help me with topic";
    &leave();
}
else {

    &SDB_help();
    &leave();
}

exit;

##############
sub leave {
##############
    #
    # Tidy up if necessary...
    #
    exit;
}

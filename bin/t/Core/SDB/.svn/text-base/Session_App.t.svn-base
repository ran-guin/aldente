#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;
use CGI qw(:standard);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::Session_App;
############################
my $host = $Configs{UNIT_TEST_HOST};
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################



use_ok("SDB::Session_App");


my $sessapp = SDB::Session_App->new(PARAMS => {dbc => $dbc});


if ( !$method || $method=~/\bsetup\b/ ) {
    can_ok("SDB::Session_App", 'setup');
    {
        ## <insert tests for new method here> ##
    }
}


if ( !$method || $method=~/\bsearch_page\b/ ) {
    can_ok("SDB::Session_App", 'search_page');
    {
    }
}

if ( !$method || $method=~/\bdisplay_Session_details\b/ ) {
    can_ok("SDB::Session_App", 'display_Session_details');
    {
    }
}


if ( !$method || $method=~/\bdisplay_Sessions_List\b/ ) {
    can_ok("SDB::Session_App", 'display_Sessions_List');
    {
    }
}

## END of TEST ##

ok( 1 ,'Completed Session_App test');

exit;

#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
my $dbase  = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("SDB::Work_Flow_App");

########################
## Add Run Mode Tests ##
########################
my $page;    ## output from respective run mode (Use RGTools::Unit_Test methods to check for output tables etc)

### Previous ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'SDB::Work_Flow_App',-rm=>'Previous', -Params=> {});

### Start Work Flow ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'SDB::Work_Flow_App',-rm=>'Start Work Flow', -Params=> {});

### Next ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'SDB::Work_Flow_App',-rm=>'Next', -Params=> {});

## END of TEST ##

ok( 1 ,'Completed Work_Flow_App test');

exit;

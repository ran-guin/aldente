#!/usr/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Run_App;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Run_App");

########################
## Add Run Mode Tests ##
########################
my $page;

### Set Run Test Status ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'Set Run Test Status', -Params=> {});

### View Analysis ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'View Analysis', -Params=> {});

### Mark Failed Runs ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'Mark Failed Runs', -Params=> {username=>'tom'});

### Default Page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'Default Page', -Params=> {});

### Home Page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'Home Page', -Params=> {});

### Summary Page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'Summary Page', -Params=> {});

### Annotate Run Comments ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'Annotate Run Comments', -Params=> {});

### List Page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'List Page', -Params=> {});

### Remove Run Request ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'Remove Run Request', -Params=> {});

### Search Page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'Search Page', -Params=> {});

### View Runs ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Run_App',-rm=>'View Runs', -Params=> {});

## END of TEST ##

print "\n\n";

ok( 1 ,'Completed Run_App test');

exit;

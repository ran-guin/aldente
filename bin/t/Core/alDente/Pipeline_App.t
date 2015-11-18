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
use_ok("alDente::Pipeline_App");

########################
## Add Run Mode Tests ##
########################
my $page;    ## output from respective run mode (Use RGTools::Unit_Test methods to check for output tables etc)

### Add Pipeline Step ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Pipeline_App',-rm=>'Add Pipeline Step', -Params=> {});

### Save Re-Ordered Pipeline ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Pipeline_App',-rm=>'Save Re-Ordered Pipeline', -Params=> {});

### summary_page ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Pipeline_App',-rm=>'summary_page', -Params=> {});

### reset_pipeline ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Pipeline_App',-rm=>'reset_pipeline', -Params=> {});

### Delete Pipeline Step ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Pipeline_App',-rm=>'Delete Pipeline Step', -Params=> {});

### home_page ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Pipeline_App',-rm=>'home_page', -Params=> {});

### Re-Order Pipeline ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Pipeline_App',-rm=>'Re-Order Pipeline', -Params=> {});

## END of TEST ##

ok( 1 ,'Completed Pipeline_App test');

exit;

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
use alDente::Document_App;
############################

############################################


use_ok("alDente::Document_App");

########################
## Add Run Mode Tests ##
########################
my $page;    ## output from respective run mode (Use RGTools::Unit_Test methods to check for output tables etc)

### Home ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Document_App',-rm=>'Home', -Params=> {});

### View Modules ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Document_App',-rm=>'View Modules', -Params=> {});

## END of TEST ##

ok( 1 ,'Completed Document_App test');

exit;

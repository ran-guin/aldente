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
use alDente::Prep_App;
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




use_ok("alDente::Prep_App");

########################
## Add Run Mode Tests ##
########################
my $page;

### alDente : Completed Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Completed Step', -Params=> {});

### alDente : Skip Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Skip Step', -Params=> {});

### Go Back One Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Go Back One Step', -Params=> {});

### Show Prep ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Show Prep', -Params=> {});

### Batch Update ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Batch Update', -Params=> {});

### Repeat Last Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Repeat Last Step', -Params=> {});

### Continue with Production Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Continue with Production Protocol', -Params=> {});

### Fail Prep, Remove Container(s) from Set ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Fail Prep, Remove Container(s) from Set', -Params=> {});

### Continue with Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Continue with Protocol', -Params=> {});

### Re-Print Plate Barcodes ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Re-Print Plate Barcodes', -Params=> {});

### Prep Notes ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Prep Notes', -Params=> {});

### Fail Step ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Fail Step', -Params=> {});

### Continue with Approved TechD Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Continue with Approved TechD Protocol', -Params=> {});

### Continue with Lab Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Continue with Lab Protocol', -Params=> {});

### Continue with Pending TechD Protocol ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Continue with Pending TechD Protocol', -Params=> {});

### Edit Prep ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Edit Prep', -Params=> {});

### Update Steps Completed ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Prep_App',-rm=>'Update Steps Completed', -Params=> {});

## END of TEST ##

ok( 1 ,'Completed Prep_App test');

exit;

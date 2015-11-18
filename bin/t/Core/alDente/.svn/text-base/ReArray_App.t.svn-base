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
use alDente::ReArray_App;
############################

############################################


use_ok("alDente::ReArray_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::ReArray_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bdefault_page\b/ ) {
    can_ok("alDente::ReArray_App", 'default_page');
    {
        ## <insert tests for default_page method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::ReArray_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::ReArray_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_page\b/ ) {
    can_ok("alDente::ReArray_App", 'search_page');
    {
        ## <insert tests for search_page method here> ##
    }
}



########################
## Add Run Mode Tests ##
########################
my $page;    ## output from respective run mode (Use RGTools::Unit_Test methods to check for output tables etc)

### Generate DNA Multiprobe ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Generate DNA Multiprobe', -Params=> {});

### Abort Rearrays ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Abort Rearrays', -Params=> {});

### Rearray Summary ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Rearray Summary', -Params=> {});

### Submit ReArray/Pool Request ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Submit ReArray/Pool Request', -Params=> {});

### Show QPIX Rack ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Show QPIX Rack', -Params=> {});

### Batch Pooling Sources ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Batch Pooling Sources', -Params=> {});

### Move to Completed ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Move to Completed', -Params=> {});

### Generate Custom Primer Multiprobe ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Generate Custom Primer Multiprobe', -Params=> {});

### Confirmed ReArray/Pool Request ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Confirmed ReArray/Pool Request', -Params=> {});

### Regenerate QPIX File ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Regenerate QPIX File', -Params=> {});

### Primer Plate Summary ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Primer Plate Summary', -Params=> {});

### Write to QPIX File ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Write to QPIX File', -Params=> {});

### View ReArrays ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'View ReArrays', -Params=> {'test' => 1});

### Generate Multiprobe ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Generate Multiprobe', -Params=> {});

### View ReArray ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'View ReArray', -Params=> {});

### Group into Lab Request ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Group into Lab Request', -Params=> {});

### ReArray Wells ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'ReArray Wells', -Params=> {'test' => 1});
### View Primer Plates ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'View Primer Plates', -Params=> {'test' => 1});

### default_page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'default_page', -Params=> {});

### Pool To Single Tube ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Pool To Single Tube', -Params=> {});

### Create ReArray ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Create ReArray', -Params=> {});

### Batch ReArray/Pool Wells ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Batch ReArray/Pool Wells', -Params=> {});

### ReArray/Pool Wells ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'ReArray/Pool Wells', -Params=> {});

### Apply Rearrays ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Apply Rearrays', -Params=> {});

### Locations ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Locations', -Params=> {});

### search_page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'search_page', -Params=> {});

### Source Primer Plate Count ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Source Primer Plate Count', -Params=> {});

### Manually Set Up ReArray/Pooling ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Manually Set Up ReArray/Pooling', -Params=> {});

### View rearray source plates in one table ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'View rearray source plates in one table', -Params=> {});

### Upload Qpix Log ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Upload Qpix Log', -Params=> {'test' => 1});

### Confirm QPix Log ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Confirm QPix Log', -Params=> {'test' => 1});

### Set Primer Plate Well Status ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Set Primer Plate Well Status', -Params=> {}); Old?

### Create Remapped Custom Primer Plate ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Create Remapped Custom Primer Plate', -Params=> {});

### Generate ReArray Span-8 csv ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Generate ReArray Span-8 csv', -Params=> {});

### Complete ReArray Specification ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Complete ReArray Specification', -Params=> {});

### Upload Yield Report ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Upload Yield Report', -Params=> {'test' => 1});

### Source Plate Count ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Source Plate Count', -Params=> {});

### rearray_map ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'rearray_map', -Params=> {});

### Pool To Tube By Rows ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Pool To Tube By Rows', -Params=> {});

### Save manual rearray ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'Save manual rearray', -Params=> {});

### home_page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::ReArray_App',-rm=>'home_page', -Params=> {});

## END of TEST ##
print "\n";
ok( 1 ,'Completed ReArray_App test');

exit;

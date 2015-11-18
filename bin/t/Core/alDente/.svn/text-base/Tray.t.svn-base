#!/usr/local/bin/perl
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
use alDente::Tray;
############################

############################################


use_ok("alDente::Tray");

my $self = new alDente::Tray(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Tray", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload\b/ ) {
    can_ok("alDente::Tray", 'load');
    {
        ## <insert tests for load method here> ##
    }
}

if ( !$method || $method=~/\bstore\b/ ) {
    can_ok("alDente::Tray", 'store');
    {
        ## <insert tests for store method here> ##
    }
}

if ( !$method || $method=~/\bcreate_multiple_trays\b/ ) {
    can_ok("alDente::Tray", 'create_multiple_trays');
    {
        ## <insert tests for create_multiple_trays method here> ##
    }
}

if ( !$method || $method=~/\b_distribute_on_tray\b/ ) {
    can_ok("alDente::Tray", '_distribute_on_tray');
    {
        ## <insert tests for _distribute_on_tray method here> ##
    }
}

if ( !$method || $method=~/\bexists_on_tray\b/ ) {
    can_ok("alDente::Tray", 'exists_on_tray');
    {
        ## <insert tests for exists_on_tray method here> ##
    }
}

if ( !$method || $method=~/\bget_content\b/ ) {
    can_ok("alDente::Tray", 'get_content');
    {
        ## <insert tests for get_content method here> ##
    }
}

if ( !$method || $method=~/\bgroup_ids\b/ ) {
    can_ok("alDente::Tray", 'group_ids');
    {
        ## <insert tests for group_ids method here> ##
    }
}

if ( !$method || $method=~/\b_update_tray_index\b/ ) {
    can_ok("alDente::Tray", '_update_tray_index');
    {
        ## <insert tests for _update_tray_index method here> ##
    }

}

if ( !$method || $method=~/\bconvert_tray_to_plate\b/ ) {
    can_ok("alDente::Tray", 'convert_tray_to_plate');
    {
        ## <insert tests for _update_tray_index method here> ##
        
        $result = alDente::Tray::convert_tray_to_plate($dbc,"Pla5000");
        is($result,'Pla5000',"Correct for single Plate barcode");

        $result = alDente::Tray::convert_tray_to_plate($dbc,"pla5000pla6000pla8000");
        is($result,'pla5000pla6000pla8000',"Correct for multiple Plate barcode");

        $result = alDente::Tray::convert_tray_to_plate($dbc,"tra99");
        is($result,'Pla9838Pla9839Pla9840Pla9841',"Correct for single Tray barcode");

        $result = alDente::Tray::convert_tray_to_plate($dbc,"tra95tra98tra99");
        is($result,'Pla9778Pla9800Pla9801Pla9802Pla9803Pla9838Pla9839Pla9840Pla9841',"Correct for multiple Tray barcode");
        $result = alDente::Tray::convert_tray_to_plate($dbc,"Tra98Pla5000tra99Pla6000");
        is($result,'Pla9800Pla9801Pla9802Pla9803Pla5000Pla9838Pla9839Pla9840Pla9841Pla6000',"Correct for mix of Tray/Plate barcode");
    }

}

## END of TEST ##

ok( 1 ,'Completed Tray test');

exit;

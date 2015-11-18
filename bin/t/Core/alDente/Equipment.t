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
use alDente::Equipment;
############################

############################################


use_ok("alDente::Equipment");

my $self = new alDente::Equipment(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Equipment", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Equipment", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bhome_info\b/ ) {
    can_ok("alDente::Equipment", 'home_info');
    {
        ## <insert tests for home_info method here> ##
    }
}

if ( !$method || $method=~/\bequipment_main\b/ ) {
    can_ok("alDente::Equipment", 'equipment_main');
    {
        ## <insert tests for equipment_main method here> ##
    }
}

if ( !$method || $method=~/\bnew_equipment\b/ ) {
    can_ok("alDente::Equipment", 'new_equipment');
    {
        ## <insert tests for new_equipment method here> ##
    }
}

if ( !$method || $method=~/\bsave_equipment\b/ ) {
    can_ok("alDente::Equipment", 'save_equipment');
    {
        ## <insert tests for save_equipment method here> ##
    }
}

if ( !$method || $method=~/\bequipment_list\b/ ) {
    can_ok("alDente::Equipment", 'equipment_list');
    {
        ## <insert tests for equipment_list method here> ##
    }
}

if ( !$method || $method=~/\bchange_matrix\b/ ) {
    can_ok("alDente::Equipment", 'change_matrix');
    {
        ## <insert tests for change_matrix method here> ##
    }
}

if ( !$method || $method=~/\bchange_MatrixBuffer\b/ ) {
    can_ok("alDente::Equipment", 'change_MatrixBuffer');
    {
        ## <insert tests for change_MatrixBuffer method here> ##
    }
}

if ( !$method || $method=~/\bmaintenance_home\b/ ) {
    can_ok("alDente::Equipment", 'maintenance_home');
    {
        ## <insert tests for maintenance_home method here> ##
    }
}

if ( !$method || $method=~/\bsave_maintenance_procedure\b/ ) {
    can_ok("alDente::Equipment", 'save_maintenance_procedure');
    {
        ## <insert tests for save_maintenance_procedure method here> ##
    }
}

if ( !$method || $method=~/\bmaintenance_stats\b/ ) {
    can_ok("alDente::Equipment", 'maintenance_stats');
    {
        ## <insert tests for maintenance_stats method here> ##
    }
}

if ( !$method || $method=~/\bshow_cap_stats\b/ ) {
    can_ok("alDente::Equipment", 'show_cap_stats');
    {
        ## <insert tests for show_cap_stats method here> ##
    }
}


if ( !$method || $method=~/\bget_MatrixBuffer\b/ ) {
    can_ok("alDente::Equipment", 'get_MatrixBuffer');
    {
        ## <insert tests for get_MatrixBuffer method here> ##
    }
}


## END of TEST ##

ok( 1 ,'Completed Equipment test');

exit;

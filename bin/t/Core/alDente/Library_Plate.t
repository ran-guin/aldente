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
use alDente::Library_Plate;
############################

############################################


use_ok("alDente::Library_Plate");

my $self = new alDente::Library_Plate(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Library_Plate", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Library_Plate", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}







if ( !$method || $method=~/\breset_SubQuadrants\b/ ) {
    can_ok("alDente::Library_Plate", 'reset_SubQuadrants');
    {
        ## <insert tests for reset_SubQuadrants method here> ##
    }
}





if ( !$method || $method=~/\bget_next_Plate\b/ ) {
    can_ok("alDente::Library_Plate", 'get_next_Plate');
    {
        ## <insert tests for get_next_Plate method here> ##
    }
}

if ( !$method || $method=~/\bLP_child_form\b/ ) {
    can_ok("alDente::Library_Plate", 'LP_child_form');
    {
        ## <insert tests for LP_child_form method here> ##
    }
}

if ( !$method || $method=~/\bshow_DNA_info\b/ ) {
    can_ok("alDente::Library_Plate", 'show_DNA_info');
    {
        ## <insert tests for show_DNA_info method here> ##
    }
}

if ( !$method || $method=~/\bshow_Map\b/ ) {
    can_ok("alDente::Library_Plate", 'show_Map');
    {
        ## <insert tests for show_Map method here> ##
    }
}

if ( !$method || $method=~/\bshow_well_map\b/ ) {
    can_ok("alDente::Library_Plate", 'show_well_map');
    {
        ## <insert tests for show_well_map method here> ##
    }
}


if ( !$method || $method=~/\bset_Wells\b/ ) {
    can_ok("alDente::Library_Plate", 'set_Wells');
    {
        ## <insert tests for set_Wells method here> ##
    }
}





if ( !$method || $method=~/\bparse_transfer_wells\b/ ) {
    can_ok("alDente::Library_Plate", 'parse_transfer_wells');
    {
        ## <insert tests for parse_transfer_wells method here> ##
    }
}

if ( !$method || $method=~/\bnot_wells\b/ ) {
    can_ok("alDente::Library_Plate", 'not_wells');
    {
        my @not = alDente::Library_Plate::not_wells('A01','96-well');
        ok(!grep(/A01/,@not),"Excludes A01");
        ok(grep(/A02/,@not),"Includes A02");
        
        #TODO: {
        #my @not = alDente::Library_Plate::not_wells('a,b','384-well');
        #ok(grep(/A02/,@not),'quadrant b includes A02');
        #ok(!grep(/B01/,@not),'quadrant a,b excludes B01');
        #}
        
        my @not = alDente::Library_Plate::not_wells('a,b,c','96-well');
        is_deeply(\@not,[],'empty string returned if invalid input');
    }
}

if ( !$method || $method=~/\bparse_rearray_options\b/ ) {
    can_ok("alDente::Library_Plate", 'parse_rearray_options');
    {
        ## <insert tests for parse_rearray_options method here> ##
    }
}

if ( !$method || $method=~/\bparse_rearray_wells\b/ ) {
    can_ok("alDente::Library_Plate", 'parse_rearray_wells');
    {
        ## <insert tests for parse_rearray_wells method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_wells_for_rearray\b/ ) {
    can_ok("alDente::Library_Plate", 'display_wells_for_rearray');
    {
        ## <insert tests for display_wells_for_rearray method here> ##
    }
}

if ( !$method || $method=~/\bview_plate\b/ ) {
    can_ok("alDente::Library_Plate", 'view_plate');
    {
        ## <insert tests for view_plate method here> ##
    }
}

if ( !$method || $method=~/\bconvert_to_original\b/ ) {
    can_ok("alDente::Library_Plate", 'convert_to_original');
    {
        ## <insert tests for convert_to_original method here> ##
    }
}

if ( !$method || $method=~/\badd_Plate\b/ ) {
    can_ok("alDente::Library_Plate", 'add_Plate');
    {
        ## <insert tests for add_Plate method here> ##
    }
}



## END of TEST ##

ok( 1 ,'Completed Library_Plate test');

exit;

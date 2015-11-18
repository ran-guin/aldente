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
use alDente::GelRun;
############################

############################################


use_ok("alDente::GelRun");

my $self = new alDente::GelRun(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::GelRun", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("alDente::GelRun", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::GelRun", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\brequest_broker\b/ ) {
    can_ok("alDente::GelRun", 'request_broker');
    {
        ## <insert tests for request_broker method here> ##
    }
}

if ( !$method || $method=~/\bgel_request_form\b/ ) {
    can_ok("alDente::GelRun", 'gel_request_form');
    {
        ## <insert tests for gel_request_form method here> ##
    }
}

if ( !$method || $method=~/\bstart_gelruns\b/ ) {
    can_ok("alDente::GelRun", 'start_gelruns');
    {
        ## <insert tests for start_gelruns method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_actions\b/ ) {
    can_ok("alDente::GelRun", 'display_actions');
    {
        ## <insert tests for display_actions method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_Gel_Lanes\b/ ) {
    can_ok("alDente::GelRun", 'display_Gel_Lanes');
    {
        ## <insert tests for display_Gel_Lanes method here> ##
    }
}

if ( !$method || $method=~/\bget_Bands\b/ ) {
    can_ok("alDente::GelRun", 'get_Bands');
    {
        ## <insert tests for get_Bands method here> ##
    }
}

if ( !$method || $method=~/\bcreate_Bands\b/ ) {
    can_ok("alDente::GelRun", 'create_Bands');
    {
        ## <insert tests for create_Bands method here> ##
    }
}

if ( !$method || $method=~/\bconfirm_create_bands\b/ ) {
    can_ok("alDente::GelRun", 'confirm_create_bands');
    {
        ## <insert tests for confirm_create_bands method here> ##
    }
}

if ( !$method || $method=~/\bconfirm_pick_bands\b/ ) {
    can_ok("alDente::GelRun", 'confirm_pick_bands');
    {
        ## <insert tests for confirm_pick_bands method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_gel_extraction\b/ ) {
    can_ok("alDente::GelRun", 'display_gel_extraction');
    {
        ## <insert tests for display_gel_extraction method here> ##
    }
}

if ( !$method || $method=~/\badd_geltray\b/ ) {
    can_ok("alDente::GelRun", 'add_geltray');
    {
        ## <insert tests for add_geltray method here> ##
    }
}

if ( !$method || $method=~/\b_get_Vector_Size\b/ ) {
    can_ok("alDente::GelRun", '_get_Vector_Size');
    {
        ## <insert tests for _get_Vector_Size method here> ##
    }
}

if ( !$method || $method=~/\b_read_sizes\b/ ) {
    can_ok("alDente::GelRun", '_read_sizes');
    {
        ## <insert tests for _read_sizes method here> ##
    }
}

if ( !$method || $method=~/\bmove_geltray_to_equ\b/ ) {
    can_ok("alDente::GelRun", 'move_geltray_to_equ');
    {
        ### position...
        &alDente::GelRun::move_geltray_to_equ($dbc,26230,530);

        ### Gel Tray
        &alDente::GelRun::move_geltray_to_equ($dbc,26252,530);

        ## <insert tests for _read_sizes method here> ##
    }
}

if ( !$method || $method=~/\b_gel_started\b/ ) {
    can_ok("alDente::GelRun", '_gel_started');
    {
        ## <insert tests for _gel_started method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed GelRun test');

exit;


=comment

    my $self = shift;   
    my %args = &filter_input(\@_);
    my $dbc = $args{-dbc} || $Connection;
    my $methods = $args{-methods};

    if (not defined $methods or $methods =~ /\bstart_gelruns\b/) {
# +--------------+----------------+
# | Equipment_ID | Equipment_name |
# +--------------+----------------+
# |          179 | Gel Box 1      |
# |          180 | Gel Box 2      |
# |          181 | Gel Box 3      |
# |          182 | Gel Box 4      |
# |          531 | C1             |
# |          532 | C3             |
# |          533 | C4             |
# |          534 | C5             |
# +--------------+----------------+
# 
# +---------+-------------------+
# | Rack_ID | Rack_Alias        |
# +---------+-------------------+
# |   25879 | Cart #1 R1-Top    |
# |   25880 | Cart #1 R1-Bottom |
# |   25881 | Cart #1 R2-Top    |
# |   25882 | Cart #1 R2-Bottom |
# |   25883 | Cart #1 R3-Top    |
# |   25884 | Cart #1 R3-Bottom |
# |   25885 | Cart #1 R4-Top    |
# |   25886 | Cart #1 R4-Bottom |
# |   25887 | Cart #1 R5-Top    |
# |   25888 | Cart #1 R5-Bottom |
# +---------+-------------------+
# 
# +-------------+------------------------+
# | Solution_ID | Stock_Name             |
# +-------------+------------------------+
# |       60877 | NuSieve 3:1 Agarose    |
# |       49285 | Sea Plaque GTG agarose |
# |       48282 | SeaKem LE Agarose      |
# |       47425 | LE Agarose             |
# +-------------+------------------------+

        
    }
    return 'completed';


=cut


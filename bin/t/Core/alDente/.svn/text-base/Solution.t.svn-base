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
use alDente::Solution;
############################

############################################


use_ok("alDente::Solution");

my $self = new alDente::Solution(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Solution", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\b_init_table\b/ ) {
    can_ok("alDente::Solution", '_init_table');
    {
        ## <insert tests for _init_table method here> ##
    }
}

if ( !$method || $method=~/\bsolution_main\b/ ) {
    can_ok("alDente::Solution", 'solution_main');
    {
        ## <insert tests for solution_main method here> ##
    }
}

if ( !$method || $method=~/\boriginal_solution\b/ ) {
    can_ok("alDente::Solution", 'original_solution');
    {
        ## <insert tests for original_solution method here> ##
    }
}

if ( !$method || $method=~/\bsave_original_solution\b/ ) {
    can_ok("alDente::Solution", 'save_original_solution');
    {
        ## <insert tests for save_original_solution method here> ##
    }
}

if ( !$method || $method=~/\bsolution_footer\b/ ) {
    can_ok("alDente::Solution", 'solution_footer');
    {
        ## <insert tests for solution_footer method here> ##
    }
}

if ( !$method || $method=~/\bidentify_mixture\b/ ) {
    can_ok("alDente::Solution", 'identify_mixture');
    {
        ## <insert tests for identify_mixture method here> ##
    }
}

if ( !$method || $method=~/\bmix_solution\b/ ) {
    can_ok("alDente::Solution", 'mix_solution');
    {
        ## <insert tests for mix_solution method here> ##
    }
}

if ( !$method || $method=~/\bsave_mixture\b/ ) {
    can_ok("alDente::Solution", 'save_mixture');
    {
        ## <insert tests for save_mixture method here> ##
    }
}

if ( !$method || $method=~/\bcombine_solutions\b/ ) {
    can_ok("alDente::Solution", 'combine_solutions');
    {
        ## <insert tests for combine_solutions method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_solution_options\b/ ) {
    can_ok("alDente::Solution", 'display_solution_options');
    {
        ## <insert tests for display_solution_options method here> ##
    }
}


if ( !$method || $method=~/\bbatch_dilute\b/ ) {
    can_ok("alDente::Solution", 'batch_dilute');
    {
        ## <insert tests for batch_dilute method here> ##
    }
}

if ( !$method || $method=~/\bmixture_options\b/ ) {
    can_ok("alDente::Solution", 'mixture_options');
    {
        ## <insert tests for mixture_options method here> ##
    }
}

if ( !$method || $method=~/\bmake_Solution\b/ ) {
    can_ok("alDente::Solution", 'make_Solution');
    {
        ## <insert tests for make_Solution method here> ##
    }
}

if ( !$method || $method=~/\bsave_standard_mixture\b/ ) {
    can_ok("alDente::Solution", 'save_standard_mixture');
    {
        ## <insert tests for save_standard_mixture method here> ##
    }
}

if ( !$method || $method=~/\bapply_solution\b/ ) {
    can_ok("alDente::Solution", 'apply_solution');
    {
        ## <insert tests for apply_solution method here> ##
    }
}

if ( !$method || $method=~/\bdispense_solution\b/ ) {
    can_ok("alDente::Solution", 'dispense_solution');
    {
        ## <insert tests for dispense_solution method here> ##
    }
}

if ( !$method || $method=~/\bempty\b/ ) {
    can_ok("alDente::Solution", 'empty');
    {
        ## <insert tests for empty method here> ##
    }
}

if ( !$method || $method=~/\bopen_bottle\b/ ) {
    can_ok("alDente::Solution", 'open_bottle');
    {
        ## <insert tests for open_bottle method here> ##
    }
}

if ( !$method || $method=~/\bunopen\b/ ) {
    can_ok("alDente::Solution", 'unopen');
    {
        ## <insert tests for unopen method here> ##
    }
}

if ( !$method || $method=~/\bstore_solution\b/ ) {
    can_ok("alDente::Solution", 'store_solution');
    {
        ## <insert tests for store_solution method here> ##
    }
}

if ( !$method || $method=~/\bnew_primer\b/ ) {
    can_ok("alDente::Solution", 'new_primer');
    {
        ## <insert tests for new_primer method here> ##
    }
}

if ( !$method || $method=~/\bsave_original_primer\b/ ) {
    can_ok("alDente::Solution", 'save_original_primer');
    {
        ## <insert tests for save_original_primer method here> ##
    }
}

if ( !$method || $method=~/\bupdate_primer\b/ ) {
    can_ok("alDente::Solution", 'update_primer');
    {
        ## <insert tests for update_primer method here> ##
    }
}

if ( !$method || $method=~/\bmore_solution_info\b/ ) {
    can_ok("alDente::Solution", 'more_solution_info');
    {
        ## <insert tests for more_solution_info method here> ##
    }
}

if ( !$method || $method=~/\border_check\b/ ) {
    can_ok("alDente::Solution", 'order_check');
    {
        ## <insert tests for order_check method here> ##
    }
}

if ( !$method || $method=~/\bget_original_reagents\b/ ) {
    can_ok("alDente::Solution", 'get_original_reagents');
    {
        ## <insert tests for get_original_reagents method here> ##
        my @reagents = alDente::Solution::get_original_reagents($dbc,85171);
        my $list = join ',', sort @reagents;
        is($list,'65507,67532,81961,81962,82502,83825,85171','retrieve list of original reagents');
        
        @reagents = alDente::Solution::get_original_reagents($dbc,85171,-unique=>1);
        $list = join ',', sort @reagents;
        is($list,'65507,67532,81961,81962,82502,85171','retrieve list of unique original reagents');
    }
}

if ( !$method || $method=~/\bget_downstream_solutions\b/ ) {
    can_ok("alDente::Solution", 'get_downstream_solutions');
    {
        ## <insert tests for get_downstream_solutions method here> ##
    }
}

if ( !$method || $method=~/\bshow_applications\b/ ) {
    can_ok("alDente::Solution", 'show_applications');
    {
        ## <insert tests for show_applications method here> ##
    }
}

if ( !$method || $method=~/\bget_reagent_amounts\b/ ) {
    can_ok("alDente::Solution", 'get_reagent_amounts');
    {
        ## <insert tests for get_reagent_amounts method here> ##
    }
}

if ( !$method || $method=~/\bexpiring_solutions\b/ ) {
    can_ok("alDente::Solution", 'expiring_solutions');
    {
        ## <insert tests for expiring_solutions method here> ##
    }
}

if ( !$method || $method=~/\bget_expiry\b/ ) {
    can_ok("alDente::Solution", 'get_expiry');
    {
        ## <insert tests for get_expiry method here> ##
    }
}

if ( !$method || $method=~/\bshow_primer_info\b/ ) {
    can_ok("alDente::Solution", 'show_primer_info');
    {
        ## <insert tests for show_primer_info method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Solution test');

exit;

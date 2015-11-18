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
use alDente::Process;
############################

############################################


use_ok("alDente::Process");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Process", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bSet_Plates\b/ ) {
    can_ok("alDente::Process", 'Set_Plates');
    {
        ## <insert tests for Set_Plates method here> ##
    }
}

if ( !$method || $method=~/\bCheck_Formats\b/ ) {
    can_ok("alDente::Process", 'Check_Formats');
    {
        ## <insert tests for Check_Formats method here> ##
    }
}

if ( !$method || $method=~/\bGet_Machine_old\b/ ) {
    can_ok("alDente::Process", 'Get_Machine_old');
    {
        ## <insert tests for Get_Machine_old method here> ##
    }
}

if ( !$method || $method=~/\bGet_Machine\b/ ) {
    can_ok("alDente::Process", 'Get_Machine');
    {
        ## <insert tests for Get_Machine method here> ##
    }
}

if ( !$method || $method=~/\bGet_Solution\b/ ) {
    can_ok("alDente::Process", 'Get_Solution');
    {
        ## <insert tests for Get_Solution method here> ##
    }
}

if ( !$method || $method=~/\bEquip_distribution\b/ ) {
    can_ok("alDente::Process", 'Equip_distribution');
    {
        ## <insert tests for Equip_distribution method here> ##
    }
}

if ( !$method || $method=~/\bMix_Solutions\b/ ) {
    can_ok("alDente::Process", 'Mix_Solutions');
    {
        ## <insert tests for Mix_Solutions method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Process test');

exit;

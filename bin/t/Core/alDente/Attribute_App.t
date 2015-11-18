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
use alDente::Attribute_App;
############################

############################################


use_ok("alDente::Attribute_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Attribute_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bdefault\b/ ) {
    can_ok("alDente::Attribute_App", 'default');
    {
        ## <insert tests for default method here> ##
    }
}

if ( !$method || $method =~ /\bsave_Attributes\b/ ) {
    can_ok("alDente::Attribute_App", 'save_Attributes');
    {
        ## <insert tests for save_Attributes method here> ##
    }
}

if ( !$method || $method =~ /\bset_Attributes\b/ ) {
    can_ok("alDente::Attribute_App", 'set_Attributes');
    {
        ## <insert tests for set_Attributes method here> ##
    }
}

if ( !$method || $method =~ /\badd_Attribute\b/ ) {
    can_ok("alDente::Attribute_App", 'add_Attribute');
    {
        ## <insert tests for add_Attribute method here> ##
    }
}

if ( !$method || $method =~ /\bdefine_Attribute\b/ ) {
    can_ok("alDente::Attribute_App", 'define_Attribute');
    {
        ## <insert tests for define_Attribute method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Attribute_App test');

exit;

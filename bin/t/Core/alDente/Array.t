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
use alDente::Array;
############################

############################################


use_ok("alDente::Array");

my $self = new alDente::Array(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Array", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Array", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bArray_button_options\b/ ) {
    can_ok("alDente::Array", 'Array_button_options');
    {
        ## <insert tests for Array_button_options method here> ##
    }
}

if ( !$method || $method=~/\bcreate_array\b/ ) {
    can_ok("alDente::Array", 'create_array');
    {
        ## <insert tests for create_array method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Array test');

exit;

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
use alDente::Clone;
############################

############################################


use_ok("alDente::Clone");

my $self = new alDente::Clone(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Clone", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Clone", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bget_info\b/ ) {
    can_ok("alDente::Clone", 'get_info');
    {
        ## <insert tests for get_info method here> ##
    }
}

if ( !$method || $method=~/\bid_by_Plate\b/ ) {
    can_ok("alDente::Clone", 'id_by_Plate');
    {
        ## <insert tests for id_by_Plate method here> ##
    }
}

if ( !$method || $method=~/\bid_by_Name\b/ ) {
    can_ok("alDente::Clone", 'id_by_Name');
    {
        ## <insert tests for id_by_Name method here> ##
    }
}

if ( !$method || $method=~/\bid_by_Run\b/ ) {
    can_ok("alDente::Clone", 'id_by_Run');
    {
        ## <insert tests for id_by_Run method here> ##
    }
}

if ( !$method || $method=~/\bupdate_data_references\b/ ) {
    can_ok("alDente::Clone", 'update_data_references');
    {
        ## <insert tests for update_data_references method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Clone\b/ ) {
    can_ok("alDente::Clone", 'update_Clone');
    {
        ## <insert tests for update_Clone method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Clone test');

exit;

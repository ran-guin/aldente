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
use alDente::Box;
############################

############################################


use_ok("alDente::Box");

my $self = new alDente::Box(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Box", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bopen_box\b/ ) {
    can_ok("alDente::Box", 'open_box');
    {
        ## <insert tests for open_box method here> ##
    }
}

if ( !$method || $method=~/\bthrow_away\b/ ) {
    can_ok("alDente::Box", 'throw_away');
    {
        ## <insert tests for throw_away method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Box test');

exit;

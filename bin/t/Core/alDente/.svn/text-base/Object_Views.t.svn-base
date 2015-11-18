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
use alDente::Object_Views;
############################

############################################


use_ok("alDente::Object_Views");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Object_Views", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bmultiple_labels\b/ ) {
    can_ok("alDente::Object_Views", 'multiple_labels');
    {
        ## <insert tests for multiple_labels method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Object_Views test');

exit;

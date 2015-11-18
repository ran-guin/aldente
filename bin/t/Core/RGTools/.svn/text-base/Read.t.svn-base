#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use RGTools::Read;
############################
############################################################
use_ok("RGTools::Read");

my $self = new Read();
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Read", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bprint\b/ ) {
    can_ok("Read", 'print');
    {
        ## <insert tests for print method here> ##
    }
}

if ( !$method || $method=~/\b_get_Q20\b/ ) {
    can_ok("Read", '_get_Q20');
    {
        ## <insert tests for _get_Q20 method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Read test');

exit;

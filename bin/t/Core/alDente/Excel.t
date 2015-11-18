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
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::Excel;
############################
############################################################
use_ok("SDB::Excel");

if ( !$method || $method=~/\bsave_Excel\b/ ) {
    can_ok("SDB::Excel", 'save_Excel');
    {
        ## <insert tests for save_Excel method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Excel test');

exit;

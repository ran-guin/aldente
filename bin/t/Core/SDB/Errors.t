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
use SDB::Errors;
############################
############################################################
use_ok("SDB::Errors");

if ( !$method || $method=~/\bsafe_glob\b/ ) {
    can_ok("SDB::Errors", 'safe_glob');
    {
        ## <insert tests for safe_glob method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Errors test');

exit;

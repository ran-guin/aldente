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
use SDB::CustomSettings;
############################
############################################################
use_ok("SDB::CustomSettings");

## END of TEST ##

ok( 1 ,'Completed CustomSettings test');

exit;

#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################################################
use_ok("Sequencing::Tools");

if ( !$method || $method =~ /\bSQL_phred\b/ ) {
    can_ok("Sequencing::Tools", 'SQL_phred');
    {
        ## <insert tests for SQL_phred method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Tools test');

exit;

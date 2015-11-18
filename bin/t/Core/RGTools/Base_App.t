#!/usr/bin/perl

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

############################################################
use_ok("RGTools::Base_App");

if ( !$method || $method =~ /\brm_link\b/ ) {
    can_ok("RGTools::Base_App", 'rm_link');
    {
        ## <insert tests for rm_link method here> ##
    }
}

if ( !$method || $method =~ /\burl_param\b/ ) {
    can_ok("RGTools::Base_App", 'url_param');
    {
        ## <insert tests for url_param method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Base_App test');

exit;

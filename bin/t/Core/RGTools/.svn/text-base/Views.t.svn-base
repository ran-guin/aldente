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
use RGTools::Views;
############################
############################################################
use_ok("RGTools::Views");

if ( !$method || $method=~/\bDraw_Map\b/ ) {
    can_ok("Views", 'Draw_Map');
    {
        ## <insert tests for Draw_Map method here> ##
    }
}

if ( !$method || $method=~/\bhtml_highlight\b/ ) {
    can_ok("Views", 'html_highlight');
    {
        ## <insert tests for html_highlight method here> ##
    }
}

if ( !$method || $method=~/\bHeading\b/ ) {
    can_ok("Views", 'Heading');
    {
        ## <insert tests for Heading method here> ##
    }
}

if ( !$method || $method=~/\bsub_Heading\b/ ) {
    can_ok("Views", 'sub_Heading');
    {
        ## <insert tests for sub_Heading method here> ##
    }
}

if ( !$method || $method=~/\bsmall_type\b/ ) {
    can_ok("Views", 'small_type');
    {
        ## <insert tests for small_type method here> ##
    }
}

if ( !$method || $method=~/\bPrint_Page\b/ ) {
    can_ok("Views", 'Print_Page');
    {
        ## <insert tests for Print_Page method here> ##
    }
}

if ( !$method || $method=~/\bfilter_header\b/ ) {
    can_ok("Views", 'filter_header');
    {
        ## <insert tests for filter_header method here> ##
    }
}

if ( !$method || $method=~/\bTable_Print\b/ ) {
    can_ok("Views", 'Table_Print');
    {
        ## <insert tests for Table_Print method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Views test');

exit;

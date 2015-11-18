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
use alDente::Department_Views;
############################

############################################


use_ok("alDente::Department_Views");

if ( !$method || $method =~ /\bsearch_record_box\b/ ) {
    can_ok("alDente::Department_Views", 'search_record_box');
    {
        ## <insert tests for search_record_box method here> ##
    }
}

if ( !$method || $method =~ /\badd_record_box\b/ ) {
    can_ok("alDente::Department_Views", 'add_record_box');
    {
        ## <insert tests for add_record_box method here> ##
    }
}

if ( !$method || $method =~ /\bexport_layer\b/ ) {
    can_ok("alDente::Department_Views", 'export_layer');
    {
        ## <insert tests for export_layer method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Department_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Department_Views test');

exit;

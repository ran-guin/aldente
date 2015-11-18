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
use alDente::GelAnalysis;
############################

############################################


use_ok("alDente::GelAnalysis");

if ( !$method || $method=~/\bimport_gel_image\b/ ) {
    can_ok("alDente::GelAnalysis", 'import_gel_image');
    {
        ## <insert tests for import_gel_image method here> ##
    }
}

if ( !$method || $method=~/\bstart_analysis\b/ ) {
    can_ok("alDente::GelAnalysis", 'start_analysis');
    {
        ## <insert tests for make_thumbnail method here> ##
    }
}

if ( !$method || $method=~/\bannotate_image\b/ ) {
    can_ok("alDente::GelAnalysis", 'annotate_image');
    {
        ## <insert tests for create_lanes method here> ##
    }
}

if ( !$method || $method=~/\bMakeThumbGel\b/ ) {
    can_ok("alDente::GelAnalysis", 'MakeThumbGel');
    {
        ## <insert tests for MakeThumbGel method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed GelAnalysis test');

exit;

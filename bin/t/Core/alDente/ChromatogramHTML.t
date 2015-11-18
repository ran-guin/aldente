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
use alDente::ChromatogramHTML;
############################

############################################


use_ok("alDente::ChromatogramHTML");

if ( !$method || $method=~/\bViewChromatogramApplet\b/ ) {
    can_ok("alDente::ChromatogramHTML", 'ViewChromatogramApplet');
    {
        ## <insert tests for ViewChromatogramApplet method here> ##
    }
}

if ( !$method || $method=~/\bViewChromatogramHelpHTML\b/ ) {
    can_ok("alDente::ChromatogramHTML", 'ViewChromatogramHelpHTML');
    {
        ## <insert tests for ViewChromatogramHelpHTML method here> ##
    }
}

if ( !$method || $method=~/\bValidRunID\b/ ) {
    can_ok("alDente::ChromatogramHTML", 'ValidRunID');
    {
        ## <insert tests for ValidRunID method here> ##
    }
}

if ( !$method || $method=~/\bValidWellID\b/ ) {
    can_ok("alDente::ChromatogramHTML", 'ValidWellID');
    {
        ## <insert tests for ValidWellID method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed ChromatogramHTML test');

exit;

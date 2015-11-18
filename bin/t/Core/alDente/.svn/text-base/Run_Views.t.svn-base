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
use alDente::Run_Views;
############################

############################################


use_ok("alDente::Run_Views");

if ( !$method || $method =~ /\bshow_run_data\b/ ) {
    can_ok("alDente::Run_Views", 'show_run_data');
    {
        ## <insert tests for show_run_data method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Run_Directory\b/ ) {
    can_ok("alDente::Run_Views", 'display_Run_Directory');
    {
        ## <insert tests for display_Run_Directory method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Sample_Sheets\b/ ) {
    can_ok("alDente::Run_Views", 'display_Sample_Sheets');
    {
        ## <insert tests for display_Sample_Sheets method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Run_Views test');

exit;

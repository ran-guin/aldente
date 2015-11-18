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
use alDente::Barcode_Views;
############################

############################################


use_ok("alDente::Barcode_Views");

if ( !$method || $method =~ /\bshow_printer_groups\b/ ) {
    can_ok("alDente::Barcode_Views", 'show_printer_groups');
    {
        ## <insert tests for show_printer_groups method here> ##
    }
}

if ( !$method || $method =~ /\b_print_button\b/ ) {
    can_ok("alDente::Barcode_Views", '_print_button');
    {
        ## <insert tests for _print_button method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_to_reset_Printer_Group\b/ ) {
    can_ok("alDente::Barcode_Views", 'prompt_to_reset_Printer_Group');
    {
        ## <insert tests for prompt_to_reset_Printer_Group method here> ##
    }
}

if ( !$method || $method =~ /\breset_Printer_button\b/ ) {
    can_ok("alDente::Barcode_Views", 'reset_Printer_button');
    {
        ## <insert tests for reset_Printer_button method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Barcode_Views test');

exit;

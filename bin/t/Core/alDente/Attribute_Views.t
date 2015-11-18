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
use alDente::Attribute_Views;
############################

############################################


use_ok("alDente::Attribute_Views");

if ( !$method || $method =~ /\bshow_attribute_link\b/ ) {
    can_ok("alDente::Attribute_Views", 'show_attribute_link');
    {
        ## <insert tests for show_attribute_link method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_for_attribute\b/ ) {
    can_ok("alDente::Attribute_Views", 'prompt_for_attribute');
    {
        ## <insert tests for prompt_for_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_for_field\b/ ) {
    can_ok("alDente::Attribute_Views", 'prompt_for_field');
    {
        ## <insert tests for prompt_for_field method here> ##
    }
}

if ( !$method || $method =~ /\bset_multiple_Attribute_form\b/ ) {
    can_ok("alDente::Attribute_Views", 'set_multiple_Attribute_form');
    {
        ## <insert tests for set_multiple_Attribute_form method here> ##
    }
}

if ( !$method || $method =~ /\bchoose_Attributes\b/ ) {
    can_ok("alDente::Attribute_Views", 'choose_Attributes');
    {
        ## <insert tests for choose_Attributes method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Attributes\b/ ) {
    can_ok("alDente::Attribute_Views", 'show_Attributes');
    {
        ## <insert tests for show_Attributes method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_batch_attribute_upload\b/ ) {
    can_ok("alDente::Attribute_Views", 'display_batch_attribute_upload');
    {
        ## <insert tests for display_batch_attribute_upload method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Attribute_Views test');

exit;

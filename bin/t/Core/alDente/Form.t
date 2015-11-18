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
use alDente::Form;
############################

############################################


use_ok("alDente::Form");

if ( !$method || $method =~ /\bstart_alDente_form\b/ ) {
    can_ok("alDente::Form", 'start_alDente_form');
    {
        ## <insert tests for start_alDente_form method here> ##
    }
}

if ( !$method || $method =~ /\bSet_Parameters\b/ ) {
    can_ok("alDente::Form", 'Set_Parameters');
    {
        ## <insert tests for Set_Parameters method here> ##
    }
}

if ( !$method || $method =~ /\b_alDente_URL_Parameters\b/ ) {
    can_ok("alDente::Form", '_alDente_URL_Parameters');
    {
        ## <insert tests for _alDente_URL_Parameters method here> ##
    }
}

if ( !$method || $method =~ /\binit_HTML_table\b/ ) {
    can_ok("alDente::Form", 'init_HTML_table');
    {
        ## <insert tests for init_HTML_table method here> ##
    }
}

if ( !$method || $method =~ /\bfail_btn\b/ ) {
    can_ok("alDente::Form", 'fail_btn');
    {
        ## <insert tests for fail_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcatch_fail_btn\b/ ) {
    can_ok("alDente::Form", 'catch_fail_btn');
    {
        ## <insert tests for catch_fail_btn method here> ##
    }
}

if ( !$method || $method =~ /\bget_form_input\b/ ) {
    can_ok("alDente::Form", 'get_form_input');
    {
        ## <insert tests for get_form_input method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Form test');

exit;

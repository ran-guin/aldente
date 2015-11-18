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
use alDente::View_Generator;
############################

############################################


use_ok("alDente::View_Generator");

if ( !$method || $method =~ /\brequest_broker\b/ ) {
    can_ok("alDente::View_Generator", 'request_broker');
    {
        ## <insert tests for request_broker method here> ##
    }
}

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::View_Generator", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::View_Generator", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bset_general_options\b/ ) {
    can_ok("alDente::View_Generator", 'set_general_options');
    {
        ## <insert tests for set_general_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_input_options\b/ ) {
    can_ok("alDente::View_Generator", 'set_input_options');
    {
        ## <insert tests for set_input_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_output_options\b/ ) {
    can_ok("alDente::View_Generator", 'set_output_options');
    {
        ## <insert tests for set_output_options method here> ##
    }
}

if ( !$method || $method =~ /\bget_output_default\b/ ) {
    can_ok("alDente::View_Generator", 'get_output_default');
    {
        ## <insert tests for get_output_default method here> ##
    }
}

if ( !$method || $method =~ /\bget_table_list\b/ ) {
    can_ok("alDente::View_Generator", 'get_table_list');
    {
        ## <insert tests for get_table_list method here> ##
    }
}

if ( !$method || $method =~ /\byaml\b/ ) {
    can_ok("alDente::View_Generator", 'yaml');
    {
        ## <insert tests for yaml method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed View_Generator test');

exit;

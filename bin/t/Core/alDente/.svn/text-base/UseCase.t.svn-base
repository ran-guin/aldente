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
use alDente::UseCase;
############################

############################################


use_ok("alDente::UseCase");


if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::UseCase", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("alDente::UseCase", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\bhome_info\b/ ) {
    can_ok("alDente::UseCase", 'home_info');
    {
        ## <insert tests for home_info method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::UseCase", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bmark_as_branch\b/ ) {
    can_ok("alDente::UseCase", 'mark_as_branch');
    {
        ## <insert tests for  mark_as_branch method here> ##
    }
}

if ( !$method || $method=~/\bdelete_step\b/ ) {
    can_ok("alDente::UseCase", 'delete_step');
    {
        ## <insert tests for  delete_step method here> ##
    }
}

if ( !$method || $method=~/\bdelete_case\b/ ) {
    can_ok("alDente::UseCase", 'delete_case');
    {
        ## <insert tests for  delete_case method here> ##
    }
}

if ( !$method || $method=~/\bview_case\b/ ) {
    can_ok("alDente::UseCase", 'view_case');
    {
        ## <insert tests for  view_case method here> ##
    }
}

if ( !$method || $method=~/\bview\b/ ) {
    can_ok("alDente::UseCase", 'view');
    {
        ## <insert tests for view method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed UseCase test');

exit;

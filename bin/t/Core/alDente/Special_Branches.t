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
use alDente::Special_Branches;
############################

############################################


use_ok("alDente::Special_Branches");

if ( !$method || $method=~/\binitialize_Form\b/ ) {
    can_ok("alDente::Special_Branches", 'initialize_Form');
    {
        ## <insert tests for initialize_Form method here> ##
    }
}

if ( !$method || $method=~/\bPre_DBForm_Skip\b/ ) {
    can_ok("alDente::Special_Branches", 'Pre_DBForm_Skip');
    {
        ## <insert tests for Pre_DBForm_Skip method here> ##
    }
}

if ( !$method || $method=~/\bPost_DBForm_Skip\b/ ) {
    can_ok("alDente::Special_Branches", 'Post_DBForm_Skip');
    {
        ## <insert tests for Post_DBForm_Skip method here> ##
    }
}

if ( !$method || $method=~/\bDB_Form_Custom_Configs\b/ ) {
    can_ok("alDente::Special_Branches", 'DB_Form_Custom_Configs');
    {
        ## <insert tests for DB_Form_Custom_Configs method here> ##
    }
}


## END of TEST ##

ok( 1 ,'Completed Special_Branches test');

exit;

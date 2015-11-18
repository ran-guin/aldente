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
use alDente::Data_Fix_App;
############################

############################################


use_ok("alDente::Data_Fix_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Data_Fix_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\btest_Stats\b/ ) {
    can_ok("alDente::Data_Fix_App", 'test_Stats');
    {
        ## <insert tests for test_Stats method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Data_Fix_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bload_file_attributes\b/ ) {
    can_ok("alDente::Data_Fix_App", 'load_file_attributes');
    {
        ## <insert tests for load_file_attributes method here> ##
    }
}

if ( !$method || $method =~ /\btest_Stats2\b/ ) {
    can_ok("alDente::Data_Fix_App", 'test_Stats2');
    {
        ## <insert tests for test_Stats2 method here> ##
    }
}

if ( !$method || $method =~ /\btmp_test_system_check\b/ ) {
    can_ok("alDente::Data_Fix_App", 'tmp_test_system_check');
    {
        ## <insert tests for tmp_test_system_check method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_dir\b/ ) {
    can_ok("alDente::Data_Fix_App", 'check_dir');
    {
        ## <insert tests for check_dir method here> ##
    }
}

if ( !$method || $method =~ /\bflag_Replacement\b/ ) {
    can_ok("alDente::Data_Fix_App", 'flag_Replacement');
    {
        ## <insert tests for flag_Replacement method here> ##
    }
}

if ( !$method || $method =~ /\bfix_preprinted_plates\b/ ) {
    can_ok("alDente::Data_Fix_App", 'fix_preprinted_plates');
    {
        ## <insert tests for fix_preprinted_plates method here> ##
    }
}

if ( !$method || $method =~ /\bmulti_table_update\b/ ) {
    can_ok("alDente::Data_Fix_App", 'multi_table_update');
    {
        ## <insert tests for multi_table_update method here> ##
    }
}

if ( !$method || $method =~ /\bfix_TCGA\b/ ) {
    can_ok("alDente::Data_Fix_App", 'fix_TCGA');
    {
        ## <insert tests for fix_TCGA method here> ##
    }
}

if ( !$method || $method =~ /\btest_trigger\b/ ) {
    can_ok("alDente::Data_Fix_App", 'test_trigger');
    {
        ## <insert tests for test_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_Plate\b/ ) {
    can_ok("alDente::Data_Fix_App", 'delete_Plate');
    {
        ## <insert tests for delete_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bfix_duplicate_Sources\b/ ) {
    can_ok("alDente::Data_Fix_App", 'fix_duplicate_Sources');
    {
        ## <insert tests for fix_duplicate_Sources method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Data_Fix_App test');

exit;

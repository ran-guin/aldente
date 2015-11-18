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
use alDente::RNA_DNA_Collection;
############################

############################################


use_ok("alDente::RNA_DNA_Collection");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::RNA_DNA_Collection", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bget_library_sub_types\b/ ) {
    can_ok("alDente::RNA_DNA_Collection", 'get_library_sub_types');
    {
        ## <insert tests for get_library_sub_types method here> ##
    }
}

if ( !$method || $method =~ /\blibrary_info\b/ ) {
    can_ok("alDente::RNA_DNA_Collection", 'library_info');
    {
        ## <insert tests for library_info method here> ##
    }
}

if ( !$method || $method =~ /\blibrary_main\b/ ) {
    can_ok("alDente::RNA_DNA_Collection", 'library_main');
    {
        ## <insert tests for library_main method here> ##
    }
}

if ( !$method || $method =~ /\bold_library_main\b/ ) {
    can_ok("alDente::RNA_DNA_Collection", 'old_library_main');
    {
        ## <insert tests for old_library_main method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed RNA_DNA_Collection test');

exit;

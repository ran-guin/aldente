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
use alDente::Patch;
############################

############################################


use_ok("alDente::Patch");

if ( !$method || $method =~ /\bpatch_DB\b/ ) {
    can_ok("alDente::Patch", 'patch_DB');
    {
        ## <insert tests for patch_DB method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_patch_file\b/ ) {
    can_ok("alDente::Patch", 'create_patch_file');
    {
        ## <insert tests for create_patch_file method here> ##
    }
}

if ( !$method || $method =~ /\bappend_patch_file\b/ ) {
    can_ok("alDente::Patch", 'append_patch_file');
    {
        ## <insert tests for append_patch_file method here> ##
    }
}

if ( !$method || $method =~ /\bprepare_query\b/ ) {
    can_ok("alDente::Patch", 'prepare_query');
    {
        ## <insert tests for prepare_query method here> ##
    }
}

if ( !$method || $method =~ /\bget_available_patches\b/ ) {
    can_ok("alDente::Patch", 'get_available_patches');
    {
        ## <insert tests for get_available_patches method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Patch test');

exit;

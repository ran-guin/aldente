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
use alDente::System_Views;
############################

############################################


use_ok("alDente::System_Views");

if ( !$method || $method =~ /\bdisplay_Entry_Page\b/ ) {
    can_ok("alDente::System_Views", 'display_Entry_Page');
    {
        ## <insert tests for display_Entry_Page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Graph\b/ ) {
    can_ok("alDente::System_Views", 'display_Graph');
    {
        ## <insert tests for display_Graph method here> ##
    }
}

if ( !$method || $method =~ /\brebuild_sizes_file\b/ ) {
    can_ok("alDente::System_Views", 'rebuild_sizes_file');
    {
        ## <insert tests for rebuild_sizes_file method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Volumes\b/ ) {
    can_ok("alDente::System_Views", 'show_Volumes');
    {
        ## <insert tests for show_Volumes method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Directories\b/ ) {
    can_ok("alDente::System_Views", 'show_Directories');
    {
        ## <insert tests for show_Directories method here> ##
    }
}

if ( !$method || $method =~ /\bshow_usage_table\b/ ) {
    can_ok("alDente::System_Views", 'show_usage_table');
    {
        ## <insert tests for show_usage_table method here> ##
    }
}

if ( !$method || $method =~ /\bshow_highlights\b/ ) {
    can_ok("alDente::System_Views", 'show_highlights');
    {
        ## <insert tests for show_highlights method here> ##
    }
}

if ( !$method || $method =~ /\breformat_data\b/ ) {
    can_ok("alDente::System_Views", 'reformat_data');
    {
        ## <insert tests for reformat_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_csv_data\b/ ) {
    can_ok("alDente::System_Views", 'get_csv_data');
    {
        ## <insert tests for get_csv_data method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed System_Views test');

exit;

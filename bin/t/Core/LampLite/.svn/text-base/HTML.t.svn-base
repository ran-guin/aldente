#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################################################
use_ok("LampLite::HTML");

if ( !$method || $method =~ /\binitialize_page\b/ ) {
    can_ok("LampLite::HTML", 'initialize_page');
    {
        ## <insert tests for initialize_page method here> ##
    }
}

if ( !$method || $method =~ /\buninitialize_page\b/ ) {
    can_ok("LampLite::HTML", 'uninitialize_page');
    {
        ## <insert tests for uninitialize_page method here> ##
    }
}

if ( !$method || $method =~ /\bbrowser_check\b/ ) {
    can_ok("LampLite::HTML", 'browser_check');
    {
        ## <insert tests for browser_check method here> ##
    }
}

if ( !$method || $method =~ /\bload_js\b/ ) {
    can_ok("LampLite::HTML", 'load_js');
    {
        ## <insert tests for load_js method here> ##
    }
}

if ( !$method || $method =~ /\bload_css\b/ ) {
    can_ok("LampLite::HTML", 'load_css');
    {
        ## <insert tests for load_css method here> ##
    }
}

if ( !$method || $method =~ /\bget_media_file\b/ ) {
    can_ok("LampLite::HTML", 'get_media_file');
    {
        ## <insert tests for get_media_file method here> ##
    }
}

if ( !$method || $method =~ /\bHTML_Dump\b/ ) {
    can_ok("LampLite::HTML", 'HTML_Dump');
    {
        ## <insert tests for HTML_Dump method here> ##
    }
}

if ( !$method || $method =~ /\b_truncated_dump\b/ ) {
    can_ok("LampLite::HTML", '_truncated_dump');
    {
        ## <insert tests for _truncated_dump method here> ##
    }
}

if ( !$method || $method =~ /\bset_validator\b/ ) {
    can_ok("LampLite::HTML", 'set_validator');
    {
        ## <insert tests for set_validator method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed HTML test');

exit;

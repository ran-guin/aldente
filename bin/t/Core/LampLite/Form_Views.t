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
use_ok("LampLite::Form_Views");

if ( !$method || $method =~ /\bsearchable_textbox\b/ ) {
    can_ok("LampLite::Form_Views", 'searchable_textbox');
    {
        ## <insert tests for searchable_textbox method here> ##
    }
}

if ( !$method || $method =~ /\bfield_prompt\b/ ) {
    can_ok("LampLite::Form_Views", 'field_prompt');
    {
        ## <insert tests for field_prompt method here> ##
    }
}

if ( !$method || $method =~ /\bprompt\b/ ) {
    can_ok("LampLite::Form_Views", 'prompt');
    {
        ## <insert tests for prompt method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Form_Views test');

exit;

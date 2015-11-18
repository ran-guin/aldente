#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use RGTools::String;
############################
############################################################
use_ok("RGTools::String");

my $self = new String();
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("String", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bfind_matches\b/ ) {
    can_ok("String", 'find_matches');
    {
        ## <insert tests for find_matches method here> ##
    }
}

if ( !$method || $method=~/\bsplit_to_screen\b/ ) {
    can_ok("String", 'split_to_screen');
    {
        ## <insert tests for split_to_screen method here> ##
    }
}

if ( !$method || $method=~/\bsplit_tagged_string\b/ ) {
    can_ok("String", 'split_tagged_string');
    {
        ## <insert tests for split_tagged_string method here> ##
    }
}

if ( !$method || $method=~/\b_index_matches\b/ ) {
    can_ok("String", '_index_matches');
    {
        ## <insert tests for _index_matches method here> ##
    }
}

if ( !$method || $method=~/\b_group_matches\b/ ) {
    can_ok("String", '_group_matches');
    {
        ## <insert tests for _group_matches method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed String test');

exit;

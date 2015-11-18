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
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use RGTools::Graph;
############################
############################################################
use_ok("RGTools::Graph");

if ( !$method || $method=~/\bgenerate_graph\b/ ) {
    can_ok("Graph", 'generate_graph');
    {
        ## <insert tests for generate_graph method here> ##
    }
}

if ( !$method || $method =~ /\bget_data_from_file\b/ ) {
    can_ok("Graph", 'get_data_from_file');
    {
        ## <insert tests for get_data_from_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_data_directly\b/ ) {
    can_ok("Graph", 'get_data_directly');
    {
        ## <insert tests for get_data_directly method here> ##
    }
}

if ( !$method || $method =~ /\bget_min_max\b/ ) {
    can_ok("Graph", 'get_min_max');
    {
        ## <insert tests for get_min_max method here> ##
    
    is_deeply( [ Graph::get_min_max(45)],[45,45],'simple scalar');
    is_deeply( [ Graph::get_min_max(45,0)],[0,45],'simple scalar with zero');
    is_deeply( [ Graph::get_min_max([12,15])],[12,15],'normal pair');
    is_deeply( [ Graph::get_min_max([25,1,32,-4])],[-4,32],'normal array with negative');
    is_deeply( [ Graph::get_min_max([[1,3,24],[-5,10,15]])],[-5,24], 'array of arrays');
    is_deeply( [ Graph::get_min_max({'A'=>5, 'B'=>22})],[5,22], 'simple hash');
    is_deeply( [ Graph::get_min_max({'A'=>[-33,2], 'B'=>[4,0]})],[-33,4], 'hash of arrays');
    }
}

if ( !$method || $method =~ /\bpad_max\b/ ) {
    can_ok("Graph", 'pad_max');
    {
        ## <insert tests for pad_max method here> ##
    is(Graph::pad_max(1.2),1.3,'1.2->1.3');
    is(Graph::pad_max(2.0),2.0,'2.0->2.0');
    is(Graph::pad_max(245.3),250,'245.3->250');
    }
}

## END of TEST ##

ok( 1 ,'Completed Graph test');

exit;

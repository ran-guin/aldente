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
use RGTools::Directory;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("RGTools::Directory");

my $self = new Directory(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Directory", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bsearch\b/ ) {
    can_ok("Directory", 'search');
    {
        ## <insert tests for search method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_html_navigator\b/ ) {
    can_ok("Directory", 'generate_html_navigator');
    {
        ## <insert tests for generate_html_navigator method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_html_info\b/ ) {
    can_ok("Directory", 'generate_html_info');
    {
        ## <insert tests for generate_html_info method here> ##
    }
}

if ( !$method || $method=~/\bsearch_directories\b/ ) {
    can_ok("Directory", 'search_directories');
    {
        ## <insert tests for search_directories method here> ##
    }
}

if ( !$method || $method=~/\bsearch_perl_files\b/ ) {
    can_ok("Directory", 'search_perl_files');
    {
        ## <insert tests for search_perl_files method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_HTML\b/ ) {
    can_ok("Directory", 'generate_HTML');
    {
        ## <insert tests for generate_HTML method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_perldoc\b/ ) {
    can_ok("Directory", 'generate_perldoc');
    {
        ## <insert tests for generate_perldoc method here> ##
    }
}

if ( !$method || $method=~/\b_build_perldoc\b/ ) {
    can_ok("Directory", '_build_perldoc');
    {
        ## <insert tests for _build_perldoc method here> ##
    }
}

if ( !$method || $method=~/\b_build_code\b/ ) {
    can_ok("Directory", '_build_code');
    {
        ## <insert tests for _build_code method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Directory test');

exit;

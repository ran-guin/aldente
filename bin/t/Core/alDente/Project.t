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
use alDente::Project;
############################

############################################


use_ok("alDente::Project");

my $self = new alDente::Project(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Project", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_info\b/ ) {
    can_ok("alDente::Project", 'home_info');
    {
        ## <insert tests for home_info method here> ##
    }
}



if ( !$method || $method=~/\blist_projects\b/ ) {
    can_ok("alDente::Project", 'list_projects');
    {
        ## <insert tests for list_projects method here> ##
    }
}

if ( !$method || $method=~/\bget_project_info\b/ ) {
    can_ok("alDente::Project", 'get_project_info');
    {
        ## <insert tests for get_project_info method here> ##
    }
}


if ( !$method || $method=~/\bget_project_stats\b/ ) {
    can_ok("alDente::Project", 'get_project_stats');
    {
        ## <insert tests for get_project_stats method here> ##
    }
}

if ( !$method || $method=~/\blist_funding_sources\b/ ) {
    can_ok("alDente::Project", 'list_funding_sources');
    {
        ## <insert tests for list_funding_sources method here> ##
        my $proj = new alDente::Project( -id => 553 );
        my @fundings = $proj->list_funding_sources();
        my @expected = ( 662 );
        is_deeply( \@fundings, \@expected, 'list_funding_sources');
    }
}

## END of TEST ##

ok( 1 ,'Completed Project test');

exit;

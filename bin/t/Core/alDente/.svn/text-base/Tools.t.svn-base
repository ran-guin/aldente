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
use alDente::Tools;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Tools");

if ( !$method || $method=~/\bSearch_Database\b/ ) {
    can_ok("alDente::Tools", 'Search_Database');
    {
        ## <insert tests for Search_Database method here> ##
    }
}

if ( !$method || $method=~/\bsearch_list\b/ ) {
    can_ok("alDente::Tools", 'search_list');
    {
        ## <insert tests for search_list method here> ##
    }
}

if ( !$method || $method=~/\bset_search_IDs\b/ ) {
    can_ok("alDente::Tools", 'set_search_IDs');
    {
        ## <insert tests for set_search_IDs method here> ##
    }
}

if ( !$method || $method=~/\bshow_well_table\b/ ) {
    can_ok("alDente::Tools", 'show_well_table');
    {
        ## <insert tests for show_well_table method here> ##
    }
}

if ( !$method || $method=~/\bcalculate\b/ ) {
    can_ok("alDente::Tools", 'calculate');
    {
        my ($res,$res_unit);
        ($res,$res_unit) = &alDente::Tools::calculate(-action=>'add',-p1_amnt=>300,-p1_units=>'ul',-p2_amnt=>200,-p2_units=>'ul');
        ok((($res == 500) and ($res_unit eq 'ul')),'Calculate: Add, same unit works');

        ($res,$res_unit) = &alDente::Tools::calculate(-action=>'subtract',-p1_amnt=>300,-p1_units=>'ul',-p2_amnt=>200,-p2_units=>'ul');
        ok((($res == 100) and ($res_unit eq 'ul')),'Calculate: Subtract, same unit works');

        ($res,$res_unit) = &alDente::Tools::calculate(-action=>'subtract',-p1_amnt=>300,-p1_units=>'ml',-p2_amnt=>200,-p2_units=>'ul');
        ok((($res == '299.8') and ($res_unit eq 'ml')),'Calculate: Subtract, diff unit works');

        ($res,$res_unit) = &alDente::Tools::calculate(-action=>'add',-p1_amnt=>600,-p1_units=>'ul',-p2_amnt=>900,-p2_units=>'ul');
        ok((($res == 1500) and ($res_unit eq 'ul')),'Calculate: Add, diff unit works');

        ($res,$res_unit) = &alDente::Tools::calculate(-action=>'subtract',-p1_amnt=>300,-p1_units=>'ul',-p2_amnt=>200,-p2_units=>'Cells');
        ok((($res == 300) and ($res_unit eq 'ul')),'Calculate: Subtract, mixed units works');

    }
}

if ( !$method || $method=~/\bLinks\b/ ) {
    can_ok("alDente::Tools", 'Links');
    {
        ## <insert tests for Links method here> ##
    }
}

if ( !$method || $method=~/\bHref\b/ ) {
    can_ok("alDente::Tools", 'Href');
    {
        ## <insert tests for Href method here> ##
    }
}

if ( !$method || $method=~/\balDente_ref\b/ ) {
    can_ok("alDente::Tools", 'alDente_ref');
    {
        ## <insert tests for alDente_ref method here> ##
    }
}

if ( !$method || $method=~/\bprintout\b/ ) {
    can_ok("alDente::Tools", 'printout');
    {
        ## <insert tests for printout method here> ##
    }
}

if ( !$method || $method=~/\binitialize_parameters\b/ ) {
    can_ok("alDente::Tools", 'initialize_parameters');
    {
        ## <insert tests for initialize_parameters method here> ##
    }
}

if ( !$method || $method=~/\bLoad_Parameters\b/ ) {
    can_ok("alDente::Tools", 'Load_Parameters');
    {
        ## <insert tests for Load_Parameters method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Tools test');

exit;

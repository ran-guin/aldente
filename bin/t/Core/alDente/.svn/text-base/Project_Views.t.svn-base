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
use alDente::Project_Views;
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




use_ok("alDente::Project_Views");

if ( !$method || $method =~ /\bhome_info\b/ ) {
    can_ok("alDente::Project_Views", 'home_info');
    {
        ## <insert tests for home_info method here> ##
    }
}

if ( !$method || $method =~ /\b_init_table\b/ ) {
    can_ok("alDente::Project_Views", '_init_table');
    {
        ## <insert tests for _init_table method here> ##
    }
}

if ( !$method || $method =~ /\b_get_stats\b/ ) {
    can_ok("alDente::Project_Views", '_get_stats');
    {
        ## <insert tests for _get_stats method here> ##
    }
}

if ( !$method || $method =~ /\blist_projects\b/ ) {
    can_ok("alDente::Project_Views", 'list_projects');
    {
        ## <insert tests for list_projects method here> ##
    }
}

if ( !$method || $method =~ /\bget_project_info_HTML\b/ ) {
    can_ok("alDente::Project_Views", 'get_project_info_HTML');
    {
        ## <insert tests for get_project_info_HTML method here> ##
    }
}

if ( !$method || $method =~ /\bshow_project_stats\b/ ) {
    can_ok("alDente::Project_Views", 'show_project_stats');
    {
        ## <insert tests for show_project_stats method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Project_Views test');

exit;

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
use alDente::DBField_App;
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




use_ok("alDente::DBField_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::DBField_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bmain_page\b/ ) {
    can_ok("alDente::DBField_App", 'main_page');
    {
        ## <insert tests for main_page method here> ##
    }
}

if ( !$method || $method =~ /\badd_field\b/ ) {
    can_ok("alDente::DBField_App", 'add_field');
    {
        ## <insert tests for add_field method here> ##
    }
}

if ( !$method || $method =~ /\badd_entry\b/ ) {
    can_ok("alDente::DBField_App", 'add_entry');
    {
        ## <insert tests for add_entry method here> ##
    }
}

if ( !$method || $method =~ /\bsearch\b/ ) {
    can_ok("alDente::DBField_App", 'search');
    {
        ## <insert tests for search method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_new_dbfield_block\b/ ) {
    can_ok("alDente::DBField_App", 'display_new_dbfield_block');
    {
        ## <insert tests for display_new_dbfield_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_block\b/ ) {
    can_ok("alDente::DBField_App", 'display_search_block');
    {
        ## <insert tests for display_search_block method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DBField_App test');

exit;

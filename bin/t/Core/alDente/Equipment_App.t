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
use alDente::Equipment_App;
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




use_ok("alDente::Equipment_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Equipment_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bassign_category\b/ ) {
    can_ok("alDente::Equipment_App", 'assign_category');
    {
        ## <insert tests for assign_category method here> ##
    }
}

if ( !$method || $method =~ /\bactivate_equipment\b/ ) {
    can_ok("alDente::Equipment_App", 'activate_equipment');
    {
        ## <insert tests for activate_equipment method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Equipment_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bentry_page\b/ ) {
    can_ok("alDente::Equipment_App", 'entry_page');
    {
        ## <insert tests for entry_page method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Equipment_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bmain_page\b/ ) {
    can_ok("alDente::Equipment_App", 'main_page');
    {
        ## <insert tests for main_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_equipment\b/ ) {
    can_ok("alDente::Equipment_App", 'list_equipment');
    {
        ## <insert tests for list_equipment method here> ##
    }
}

if ( !$method || $method =~ /\bnew_equipment\b/ ) {
    can_ok("alDente::Equipment_App", 'new_equipment');
    {
        ## <insert tests for new_equipment method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_results\b/ ) {
    can_ok("alDente::Equipment_App", 'display_search_results');
    {
        ## <insert tests for display_search_results method here> ##
    }
}

if ( !$method || $method =~ /\bdefine_demo\b/ ) {
    can_ok("alDente::Equipment_App", 'define_demo');
    {
        ## <insert tests for define_demo method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_equipment_homepage\b/ ) {
    can_ok("alDente::Equipment_App", 'display_equipment_homepage');
    {
        ## <insert tests for display_equipment_homepage method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_new_equipment_block\b/ ) {
    can_ok("alDente::Equipment_App", 'display_new_equipment_block');
    {
        ## <insert tests for display_new_equipment_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_block\b/ ) {
    can_ok("alDente::Equipment_App", 'display_search_block');
    {
        ## <insert tests for display_search_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_maintenance_block\b/ ) {
    can_ok("alDente::Equipment_App", 'display_maintenance_block');
    {
        ## <insert tests for display_maintenance_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_small_label_block\b/ ) {
    can_ok("alDente::Equipment_App", 'display_small_label_block');
    {
        ## <insert tests for display_small_label_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_large_Label_block\b/ ) {
    can_ok("alDente::Equipment_App", 'display_large_Label_block');
    {
        ## <insert tests for display_large_Label_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_tube_label_block\b/ ) {
    can_ok("alDente::Equipment_App", 'display_tube_label_block');
    {
        ## <insert tests for display_tube_label_block method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Equipment_App test');

exit;

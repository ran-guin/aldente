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
use alDente::Equipment_Views;
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




use_ok("alDente::Equipment_Views");

if ( !$method || $method =~ /\bequipment_main\b/ ) {
    can_ok("alDente::Equipment_Views", 'equipment_main');
    {
        ## <insert tests for equipment_main method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Equipment_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bequipment_label\b/ ) {
    can_ok("alDente::Equipment_Views", 'equipment_label');
    {
        ## <insert tests for equipment_label method here> ##
    }
}

if ( !$method || $method =~ /\bequipment_footer\b/ ) {
    can_ok("alDente::Equipment_Views", 'equipment_footer');
    {
        ## <insert tests for equipment_footer method here> ##
    }
}

if ( !$method || $method =~ /\bmaintenance_block\b/ ) {
    can_ok("alDente::Equipment_Views", 'maintenance_block');
    {
        ## <insert tests for maintenance_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Equipment_Activation_Button\b/ ) {
    can_ok("alDente::Equipment_Views", 'display_Equipment_Activation_Button');
    {
        ## <insert tests for display_Equipment_Activation_Button method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Equipment_Activation_Page\b/ ) {
    can_ok("alDente::Equipment_Views", 'display_Equipment_Activation_Page');
    {
        ## <insert tests for display_Equipment_Activation_Page method here> ##
    }
}

if ( !$method || $method =~ /\bmaintenance_block\b/ ) {
    can_ok("alDente::Equipment_Views", 'maintenance_block');
    {
        ## <insert tests for maintenance_block method here> ##
    }
}

if ( !$method || $method=~/\bscheduled_maintenance\b/ ) {
    can_ok("alDente::Equipment_Views", 'scheduled_maintenance');
    {
        my $view = alDente::Equipment_Views::scheduled_maintenance($dbc,-return_html=>1);
        is(Unit_Test::table_count($view),2,"returned heading + table for scheduled maintenance");
        is(Unit_Test::column_count($view),10,'returned 10 columns in maintenance view');
    }
}

if ( !$method || $method =~ /\bconfirm_MatrixBuffer\b/ ) {
    can_ok("alDente::Equipment_Views", 'confirm_MatrixBuffer');
    {
        ## <insert tests for confirm_MatrixBuffer method here> ##
    }
}

if ( !$method || $method =~ /\bnew_equipment\b/ ) {
    can_ok("alDente::Equipment_Views", 'new_equipment');
    {
        ## <insert tests for new_equipment method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Equipment_Views test');

exit;

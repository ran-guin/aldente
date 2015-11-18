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
use alDente::Primer_App;
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




use_ok("alDente::Primer_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Primer_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bentry_page\b/ ) {
    can_ok("alDente::Primer_App", 'entry_page');
    {
        ## <insert tests for entry_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Primer_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bmain_page\b/ ) {
    can_ok("alDente::Primer_App", 'main_page');
    {
        ## <insert tests for main_page method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Primer_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\breceive_primer_plate_as_tubes\b/ ) {
    can_ok("alDente::Primer_App", 'receive_primer_plate_as_tubes');
    {
        ## <insert tests for receive_primer_plate_as_tubes method here> ##
    }
}

if ( !$method || $method =~ /\bregenerate_primer_order_from_primer_plate\b/ ) {
    can_ok("alDente::Primer_App", 'regenerate_primer_order_from_primer_plate');
    {
        ## <insert tests for regenerate_primer_order_from_primer_plate method here> ##
    }
}

if ( !$method || $method =~ /\bmark_primer_plates_as_ordered\b/ ) {
    can_ok("alDente::Primer_App", 'mark_primer_plates_as_ordered');
    {
        ## <insert tests for mark_primer_plates_as_ordered method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_custom_primer_multiprobe\b/ ) {
    can_ok("alDente::Primer_App", 'generate_custom_primer_multiprobe');
    {
        ## <insert tests for generate_custom_primer_multiprobe method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_primer_orders\b/ ) {
    can_ok("alDente::Primer_App", 'delete_primer_orders');
    {
        ## <insert tests for delete_primer_orders method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_primer_home\b/ ) {
    can_ok("alDente::Primer_App", 'display_primer_home');
    {
        ## <insert tests for display_primer_home method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_intro\b/ ) {
    can_ok("alDente::Primer_App", 'display_intro');
    {
        ## <insert tests for display_intro method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_delete_Primer_Plate_table\b/ ) {
    can_ok("alDente::Primer_App", 'display_delete_Primer_Plate_table');
    {
        ## <insert tests for display_delete_Primer_Plate_table method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Primer_App test');

exit;

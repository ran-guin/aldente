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
use alDente::Diagnostics_App;
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




use_ok("alDente::Diagnostics_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Diagnostics_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Diagnostics_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\brun_diagnostics\b/ ) {
    can_ok("alDente::Diagnostics_App", 'run_diagnostics');
    {
        ## <insert tests for run_diagnostics method here> ##
    }
}

if ( !$method || $method =~ /\bshow_diagnostics\b/ ) {
    can_ok("alDente::Diagnostics_App", 'show_diagnostics');
    {
        ## <insert tests for show_diagnostics method here> ##
    }
}

if ( !$method || $method =~ /\brun_sequencing_diagnostics\b/ ) {
    can_ok("alDente::Diagnostics_App", 'run_sequencing_diagnostics');
    {
        ## <insert tests for run_sequencing_diagnostics method here> ##
    }
}

if ( !$method || $method =~ /\brun_gelrun_diagnostics\b/ ) {
    can_ok("alDente::Diagnostics_App", 'run_gelrun_diagnostics');
    {
        ## <insert tests for run_gelrun_diagnostics method here> ##
    }
}

if ( !$method || $method =~ /\bshow_zoom_in\b/ ) {
    can_ok("alDente::Diagnostics_App", 'show_zoom_in');
    {
        ## <insert tests for show_zoom_in method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Diagnostics_App test');

exit;

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
use alDente::QC_Batch_App;
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




use_ok("alDente::QC_Batch_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::QC_Batch_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\badd_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'add_Batch');
    {
        ## <insert tests for add_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bview_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'view_Batch');
    {
        ## <insert tests for view_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bpass_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'pass_Batch');
    {
        ## <insert tests for pass_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bfail_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'fail_Batch');
    {
        ## <insert tests for fail_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bretest_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'retest_Batch');
    {
        ## <insert tests for retest_Batch method here> ##
    }
}

if ( !$method || $method =~ /\brelease_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'release_Batch');
    {
        ## <insert tests for release_Batch method here> ##
    }
}

if ( !$method || $method =~ /\breject_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'reject_Batch');
    {
        ## <insert tests for reject_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bquarantine_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'quarantine_Batch');
    {
        ## <insert tests for quarantine_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_Report\b/ ) {
    can_ok("alDente::QC_Batch_App", 'generate_Report');
    {
        ## <insert tests for generate_Report method here> ##
    }
}

if ( !$method || $method =~ /\breview_Batch\b/ ) {
    can_ok("alDente::QC_Batch_App", 'review_Batch');
    {
        ## <insert tests for review_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bQC_Batch_help\b/ ) {
    can_ok("alDente::QC_Batch_App", 'QC_Batch_help');
    {
        ## <insert tests for QC_Batch_help method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed QC_Batch_App test');

exit;

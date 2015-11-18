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
use alDente::QC_Batch;
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




use_ok("alDente::QC_Batch");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::QC_Batch", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bnew_QC_Batch_trigger\b/ ) {
    can_ok("alDente::QC_Batch", 'new_QC_Batch_trigger');
    {
        ## <insert tests for new_QC_Batch_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::QC_Batch", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bdefine_Batch\b/ ) {
    can_ok("alDente::QC_Batch", 'define_Batch');
    {
        ## <insert tests for define_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bset_Batch\b/ ) {
    can_ok("alDente::QC_Batch", 'set_Batch');
    {
        ## <insert tests for set_Batch method here> ##
    }
}

if ( !$method || $method =~ /\bset_Batch_Member\b/ ) {
    can_ok("alDente::QC_Batch", 'set_Batch_Member');
    {
        ## <insert tests for set_Batch_Member method here> ##
    }
}

if ( !$method || $method =~ /\blocal_QC_tracking\b/ ) {
    can_ok("alDente::QC_Batch", 'local_QC_tracking');
    {
        ## <insert tests for local_QC_tracking method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_Quarantine\b/ ) {
    can_ok("alDente::QC_Batch", 'check_Quarantine');
    {
        ## <insert tests for check_Quarantine method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed QC_Batch test');

exit;

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
use alDente::Admin;
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




use_ok("alDente::Admin");

if ( !$method || $method=~/\bAdmin_page\b/ ) {
    can_ok("alDente::Admin", 'Admin_page');
    {
        ## <insert tests for Admin_page method here> ##
    }
}

if ( !$method || $method=~/\bReAnalyzeRuns\b/ ) {
    can_ok("alDente::Admin", 'ReAnalyzeRuns');
    {
        ## <insert tests for ReAnalyzeRuns method here> ##
    }
}

if ( !$method || $method=~/\b_init_table\b/ ) {
    can_ok("alDente::Admin", '_init_table');
    {
        ## <insert tests for _init_table method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Mirroring\b/ ) {
    can_ok("alDente::Admin", 'display_Mirroring');
    {
        ## <insert tests for display_Mirroring method here> ##
    }
}

if ( !$method || $method =~ /\bsend_status_change_notification\b/ ) {
    can_ok("alDente::Admin", 'send_status_change_notification');
    {
        ## <insert tests for send_status_change_notification method here> ##
    }
}

if ( !$method || $method =~ /\bshow_protocol_chemistry\b/ ) {
    can_ok("alDente::Admin", 'show_protocol_chemistry');
    {
        ## <insert tests for show_protocol_chemistry method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_protocol_chemistry_dropdown\b/ ) {
    can_ok("alDente::Admin", 'display_protocol_chemistry_dropdown');
    {
        ## <insert tests for display_protocol_chemistry_dropdown method here> ##
        
        ## can't create test case since $dbc->config("Security") is used in the method, while this object does not exist in $dbc created here.  
        #my $result = alDente::Admin::display_protocol_chemistry_dropdown( -dbc => $dbc, -status => 'Active', -type => 'Lab_Protocol' );
    }
}

## END of TEST ##

ok( 1 ,'Completed Admin test');

exit;

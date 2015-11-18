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
use alDente::Summary;
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




use_ok("alDente::Summary");

if ( !$method || $method=~/\bfetch_summary_cache\b/ ) {
    can_ok("alDente::Summary", 'fetch_summary_cache');
    {
        ## <insert tests for fetch_summary_cache method here> ##
    }
}

if ( !$method || $method=~/\bCacheAge\b/ ) {
    can_ok("alDente::Summary", 'CacheAge');
    {
        ## <insert tests for CacheAge method here> ##
    }
}

if ( !$method || $method=~/\bFetchData\b/ ) {
    can_ok("alDente::Summary", 'FetchData');
    {
        ## <insert tests for FetchData method here> ##
    }
}

if ( !$method || $method=~/\bprint_lib_recent_runs\b/ ) {
    can_ok("alDente::Summary", 'print_lib_recent_runs');
    {
        ## <insert tests for print_lib_recent_runs method here> ##
    }
}

if ( !$method || $method=~/\bprint_seq_recent_run_results\b/ ) {
    can_ok("alDente::Summary", 'print_seq_recent_run_results');
    {
        ## <insert tests for print_seq_recent_run_results method here> ##
    }
}

if ( !$method || $method=~/\bruns_by_lib_data\b/ ) {
    can_ok("alDente::Summary", 'runs_by_lib_data');
    {
        ## <insert tests for runs_by_lib_data method here> ##
    }
}

if ( !$method || $method=~/\bcount_slow_and_no_grows\b/ ) {
    can_ok("alDente::Summary", 'count_slow_and_no_grows');
    {
        ## <insert tests for count_slow_and_no_grows method here> ##
    }
}

if ( !$method || $method=~/\bRoundSigDig\b/ ) {
    can_ok("alDente::Summary", 'RoundSigDig');
    {
        ## <insert tests for RoundSigDig method here> ##
    }
}

if ( !$method || $method=~/\benumerateRecentRuns\b/ ) {
    can_ok("alDente::Summary", 'enumerateRecentRuns');
    {
        ## <insert tests for enumerateRecentRuns method here> ##
    }
}

if ( !$method || $method=~/\bbuild_recent_runs_table\b/ ) {
    can_ok("alDente::Summary", 'build_recent_runs_table');
    {
        ## <insert tests for build_recent_runs_table method here> ##
    }
}

if ( !$method || $method=~/\bGetQImage\b/ ) {
    can_ok("alDente::Summary", 'GetQImage');
    {
        ## <insert tests for GetQImage method here> ##
    }
}

if ( !$method || $method=~/\bsqltime2lt\b/ ) {
    can_ok("alDente::Summary", 'sqltime2lt');
    {
        ## <insert tests for sqltime2lt method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Summary test');

exit;

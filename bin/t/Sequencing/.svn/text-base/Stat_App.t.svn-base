#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host = $Configs{UNIT_TEST_HOST};
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Sequencing::Stat_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("Sequencing::Stat_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_page\b/ ) {
    can_ok("Sequencing::Stat_App", 'search_page');
    {
        ## <insert tests for search_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_sequencing_staus\b/ ) {
    can_ok("Sequencing::Stat_App", 'display_sequencing_staus');
    {
        ## <insert tests for display_sequencing_staus method here> ##
    }
}

if ( !$method || $method =~ /\bproject_stats\b/ ) {
    can_ok("Sequencing::Stat_App", 'project_stats');
    {
        ## <insert tests for project_stats method here> ##
    }
}

if ( !$method || $method =~ /\bDR_summary\b/ ) {
    can_ok("Sequencing::Stat_App", 'DR_summary');
    {
        ## <insert tests for DR_summary method here> ##
    }
}

if ( !$method || $method =~ /\bsequencer_stats\b/ ) {
    can_ok("Sequencing::Stat_App", 'sequencer_stats');
    {
        ## <insert tests for sequencer_stats method here> ##
    }
}

if ( !$method || $method =~ /\breads_summary\b/ ) {
    can_ok("Sequencing::Stat_App", 'reads_summary');
    {
        ## <insert tests for reads_summary method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_page\b/ ) {
    can_ok("Sequencing::Stat_App", 'display_search_page');
    {
        ## <insert tests for display_search_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_stat_table\b/ ) {
    can_ok("Sequencing::Stat_App", 'display_stat_table');
    {
        ## <insert tests for display_stat_table method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_project_table\b/ ) {
    can_ok("Sequencing::Stat_App", 'display_project_table');
    {
        ## <insert tests for display_project_table method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_library_search\b/ ) {
    can_ok("Sequencing::Stat_App", 'display_library_search');
    {
        ## <insert tests for display_library_search method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Stat_App test');

exit;

#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase  = $Configs{UNIT_TEST_DATABASE};
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


sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new Lib_Construction::GenechipRun(%args);

}

############################################################
use_ok("Lib_Construction::GenechipRun");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bload_Object\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\brequest_broker\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'request_broker');
    {
        ## <insert tests for request_broker method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_general\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'display_general');
    {
        ## <insert tests for display_general method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_stats\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'display_stats');
    {
        ## <insert tests for display_stats method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_mapping_stats\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'display_mapping_stats');
    {
        ## <insert tests for display_mapping_stats method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_expression_stats\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'display_expression_stats');
    {
        ## <insert tests for display_expression_stats method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_actions\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'display_actions');
    {
        ## <insert tests for display_actions method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_qc_plot\b/ ) {
    can_ok("Lib_Construction::GenechipRun", 'display_qc_plot');
    {
        ## <insert tests for display_qc_plot method here> ##
    }
}

if ( !$method || $method =~ /\b_display_samplesheet\b/ ) {
    can_ok("Lib_Construction::GenechipRun", '_display_samplesheet');
    {
        ## <insert tests for _display_samplesheet method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed GenechipRun test');

exit;

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

my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
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


sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new Statistics_View(%args);

}

############################################################
use_ok("Mapping::Statistics_View");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Mapping::Statistics_View", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_query_form\b/ ) {
    can_ok("Mapping::Statistics_View", 'display_query_form');
    {
        ## <insert tests for display_query_form method here> ##
    }
}

if ( !$method || $method =~ /\bappend_table\b/ ) {
    can_ok("Mapping::Statistics_View", 'append_table');
    {
        ## <insert tests for append_table method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Statistics_View test');

exit;

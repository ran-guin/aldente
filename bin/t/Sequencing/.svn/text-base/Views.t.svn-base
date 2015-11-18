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
use_ok("Sequencing::Views");

if ( !$method || $method =~ /\bRunPlate\b/ ) {
    can_ok("Sequencing::Views", 'RunPlate');
    {
        ## <insert tests for RunPlate method here> ##
    }
}

if ( !$method || $method =~ /\bGetBPStatus\b/ ) {
    can_ok("Sequencing::Views", 'GetBPStatus');
    {
        ## <insert tests for GetBPStatus method here> ##
    }
}

if ( !$method || $method =~ /\bQualityTable\b/ ) {
    can_ok("Sequencing::Views", 'QualityTable');
    {
        ## <insert tests for QualityTable method here> ##
    }
}

if ( !$method || $method =~ /\bStatsPlate\b/ ) {
    can_ok("Sequencing::Views", 'StatsPlate');
    {
        ## <insert tests for StatsPlate method here> ##
    }
}

if ( !$method || $method =~ /\bDisplaySequence\b/ ) {
    can_ok("Sequencing::Views", 'DisplaySequence');
    {
        ## <insert tests for DisplaySequence method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Views test');

exit;

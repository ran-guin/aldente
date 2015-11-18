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
use_ok("Sequencing::Lab_View");

if ( !$method || $method =~ /\bprep_status\b/ ) {
    can_ok("Sequencing::Lab_View", 'prep_status');
    {
        ## <insert tests for prep_status method here> ##
    }
}

if ( !$method || $method =~ /\bTrack_Plates\b/ ) {
    can_ok("Sequencing::Lab_View", 'Track_Plates');
    {
        ## <insert tests for Track_Plates method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Prepped_Plates\b/ ) {
    can_ok("Sequencing::Lab_View", 'show_Prepped_Plates');
    {
        ## <insert tests for show_Prepped_Plates method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Lab_View test');

exit;

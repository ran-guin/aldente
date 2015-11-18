#!/usr/local/bin/perl

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
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use Sequencing::Phred;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Sequencing::Phred");

# Can't test new without putting in a -file or -seqids
# my $self = new Sequencing::Phred(-dbc=>$dbc);

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Sequencing::Phred", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_read\b/ ) {
    can_ok("Sequencing::Phred", 'generate_read');
    {
        ## <insert tests for generate_read method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_distribution\b/ ) {
    can_ok("Sequencing::Phred", 'generate_distribution');
    {
        ## <insert tests for generate_distribution method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_culmulative\b/ ) {
    can_ok("Sequencing::Phred", 'generate_culmulative');
    {
        ## <insert tests for generate_culmulative method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_histogram\b/ ) {
    can_ok("Sequencing::Phred", 'generate_histogram');
    {
        ## <insert tests for generate_histogram method here> ##
    }
}

if ( !$method || $method=~/\b_parse_phred\b/ ) {
    can_ok("Sequencing::Phred", '_parse_phred');
    {
        ## <insert tests for _parse_phred method here> ##
    }
}

if ( !$method || $method=~/\b_populate_well_from_database\b/ ) {
    can_ok("Sequencing::Phred", '_populate_well_from_database');
    {
        ## <insert tests for _populate_well_from_database method here> ##
    }
}

if ( !$method || $method=~/\b_populate_well_from_file\b/ ) {
    can_ok("Sequencing::Phred", '_populate_well_from_file');
    {
        ## <insert tests for _populate_well_from_file method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Phred test');

exit;

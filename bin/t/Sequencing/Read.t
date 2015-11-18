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
use Sequencing::Read;
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
use_ok("Sequencing::Read");

my $self = new Sequencing::Read(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Sequencing::Read", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_Sequence_Runs\b/ ) {
    can_ok("Sequencing::Read", 'load_Sequence_Runs');
    {
        ## <insert tests for load_Sequence_Runs method here> ##
    }
}

if ( !$method || $method=~/\bretrieve_by_Project\b/ ) {
    can_ok("Sequencing::Read", 'retrieve_by_Project');
    {
        ## <insert tests for retrieve_by_Project method here> ##
    }
}

if ( !$method || $method=~/\bretrieve_by_Library\b/ ) {
    can_ok("Sequencing::Read", 'retrieve_by_Library');
    {
        ## <insert tests for retrieve_by_Library method here> ##
    }
}

if ( !$method || $method=~/\bretrieve_by_Run\b/ ) {
    can_ok("Sequencing::Read", 'retrieve_by_Run');
    {
        ## <insert tests for retrieve_by_Run method here> ##
    }
}

if ( !$method || $method=~/\bretrieve_by_Name\b/ ) {
    can_ok("Sequencing::Read", 'retrieve_by_Name');
    {
        ## <insert tests for retrieve_by_Name method here> ##
    }
}

if ( !$method || $method=~/\bretrieve_by_Source\b/ ) {
    can_ok("Sequencing::Read", 'retrieve_by_Source');
    {
        ## <insert tests for retrieve_by_Source method here> ##
    }
}

if ( !$method || $method=~/\bget_QL\b/ ) {
    can_ok("Sequencing::Read", 'get_QL');
    {
        ## <insert tests for get_QL method here> ##
    }
}

if ( !$method || $method=~/\bget_Phred\b/ ) {
    can_ok("Sequencing::Read", 'get_Phred');
    {
        ## <insert tests for get_Phred method here> ##
    }
}

if ( !$method || $method=~/\bget_Name\b/ ) {
    can_ok("Sequencing::Read", 'get_Name');
    {
        ## <insert tests for get_Name method here> ##
    }
}

if ( !$method || $method=~/\bcompare_runs\b/ ) {
    can_ok("Sequencing::Read", 'compare_runs');
    {
        ## <insert tests for compare_runs method here> ##
    }
}

if ( !$method || $method=~/\bblast_against\b/ ) {
    can_ok("Sequencing::Read", 'blast_against');
    {
        ## <insert tests for blast_against method here> ##
    }
}

if ( !$method || $method=~/\bparse_blastall\b/ ) {
    can_ok("Sequencing::Read", 'parse_blastall');
    {
        ## <insert tests for parse_blastall method here> ##
    }
}

if ( !$method || $method=~/\b_unpack\b/ ) {
    can_ok("Sequencing::Read", '_unpack');
    {
        ## <insert tests for _unpack method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Read test');

exit;

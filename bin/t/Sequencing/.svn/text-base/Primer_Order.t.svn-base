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
use_ok("Sequencing::Primer_Order");

if ( !$method || $method =~ /\bgenerate_primer_order_file\b/ ) {
    can_ok("Sequencing::Primer_Order", 'generate_primer_order_file');
    {
        ## <insert tests for generate_primer_order_file method here> ##
    }
}

if ( !$method || $method =~ /\bread_yield_report\b/ ) {
    can_ok("Sequencing::Primer_Order", 'read_yield_report');
    {
        ## <insert tests for read_yield_report method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_Illumina_order_text\b/ ) {
    can_ok("Sequencing::Primer_Order", '_generate_Illumina_order_text');
    {
        ## <insert tests for _generate_Illumina_order_text method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_Illumina_order_xls\b/ ) {
    can_ok("Sequencing::Primer_Order", '_generate_Illumina_order_xls');
    {
        ## <insert tests for _generate_Illumina_order_xls method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_Invitrogen_order_xls\b/ ) {
    can_ok("Sequencing::Primer_Order", '_generate_Invitrogen_order_xls');
    {
        ## <insert tests for _generate_Invitrogen_order_xls method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_IDT_order_xls\b/ ) {
    can_ok("Sequencing::Primer_Order", '_generate_IDT_order_xls');
    {
        ## <insert tests for _generate_IDT_order_xls method here> ##
    }
}

if ( !$method || $method =~ /\b_read_Illumina_yield_report\b/ ) {
    can_ok("Sequencing::Primer_Order", '_read_Illumina_yield_report');
    {
        ## <insert tests for _read_Illumina_yield_report method here> ##
    }
}

if ( !$method || $method =~ /\b_read_Invitrogen_yield_report\b/ ) {
    can_ok("Sequencing::Primer_Order", '_read_Invitrogen_yield_report');
    {
        ## <insert tests for _read_Invitrogen_yield_report method here> ##
    }
}

if ( !$method || $method =~ /\b_read_IDT_yield_report\b/ ) {
    can_ok("Sequencing::Primer_Order", '_read_IDT_yield_report');
    {
        ## <insert tests for _read_IDT_yield_report method here> ##
    }
}

if ( !$method || $method =~ /\b_read_batch_IDT_yield_report\b/ ) {
    can_ok("Sequencing::Primer_Order", '_read_batch_IDT_yield_report');
    {
        ## <insert tests for _read_batch_IDT_yield_report method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Primer_Order test');

exit;

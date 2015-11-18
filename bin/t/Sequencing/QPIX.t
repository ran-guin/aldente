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
use_ok("Sequencing::QPIX");

if ( !$method || $method =~ /\bwrite_qpix_file\b/ ) {
    can_ok("Sequencing::QPIX", 'write_qpix_file');
    {
        ## <insert tests for write_qpix_file method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_qpix_source_only\b/ ) {
    can_ok("Sequencing::QPIX", '_generate_qpix_source_only');
    {
        ## <insert tests for _generate_qpix_source_only method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_qpix_source_and_destination\b/ ) {
    can_ok("Sequencing::QPIX", '_generate_qpix_source_and_destination');
    {
        ## <insert tests for _generate_qpix_source_and_destination method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_qpix\b/ ) {
    can_ok("Sequencing::QPIX", 'generate_qpix');
    {
        ## <insert tests for generate_qpix method here> ##
    }
}

if ( !$method || $method =~ /\bwrite_qpix_to_disk\b/ ) {
    can_ok("Sequencing::QPIX", 'write_qpix_to_disk');
    {
        ## <insert tests for write_qpix_to_disk method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_qpix_options\b/ ) {
    can_ok("Sequencing::QPIX", 'prompt_qpix_options');
    {
        ## <insert tests for prompt_qpix_options method here> ##
    }
}

if ( !$method || $method =~ /\bview_qpix_rack\b/ ) {
    can_ok("Sequencing::QPIX", 'view_qpix_rack');
    {
        ## <insert tests for view_qpix_rack method here> ##
    }
}

if ( !$method || $method =~ /\b_rack_mapping\b/ ) {
    can_ok("Sequencing::QPIX", '_rack_mapping');
    {
        ## <insert tests for _rack_mapping method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed QPIX test');

exit;

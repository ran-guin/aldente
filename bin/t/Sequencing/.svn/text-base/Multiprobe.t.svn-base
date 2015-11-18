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
use_ok("Sequencing::Multiprobe");

if ( !$method || $method =~ /\bgenerate_multiprobe\b/ ) {
    can_ok("Sequencing::Multiprobe", 'generate_multiprobe');
    {
        ## <insert tests for generate_multiprobe method here> ##
    }
}

if ( !$method || $method =~ /\bwrite_multiprobe_file\b/ ) {
    can_ok("Sequencing::Multiprobe", 'write_multiprobe_file');
    {
        ## <insert tests for write_multiprobe_file method here> ##
    }
}

if ( !$method || $method =~ /\bparse_multiprobe_string_for_primer_plates\b/ ) {
    can_ok("Sequencing::Multiprobe", 'parse_multiprobe_string_for_primer_plates');
    {
        ## <insert tests for parse_multiprobe_string_for_primer_plates method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_multiprobe_limit\b/ ) {
    can_ok("Sequencing::Multiprobe", 'prompt_multiprobe_limit');
    {
        ## <insert tests for prompt_multiprobe_limit method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_rearray_primer_multiprobe\b/ ) {
    can_ok("Sequencing::Multiprobe", '_generate_rearray_primer_multiprobe');
    {
        ## <insert tests for _generate_rearray_primer_multiprobe method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_primer_multiprobe\b/ ) {
    can_ok("Sequencing::Multiprobe", '_generate_primer_multiprobe');
    {
        ## <insert tests for _generate_primer_multiprobe method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_DNA_multiprobe\b/ ) {
    can_ok("Sequencing::Multiprobe", '_generate_DNA_multiprobe');
    {
        ## <insert tests for _generate_DNA_multiprobe method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Multiprobe test');

exit;

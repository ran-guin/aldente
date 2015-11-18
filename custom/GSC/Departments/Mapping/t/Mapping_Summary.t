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


############################################################
use_ok("Mapping::Mapping_Summary");

if ( !$method || $method =~ /\bset_general_options\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'set_general_options');
    {
        ## <insert tests for set_general_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_input_options\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'set_input_options');
    {
        ## <insert tests for set_input_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_output_options\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'set_output_options');
    {
        ## <insert tests for set_output_options method here> ##
    }
}

if ( !$method || $method =~ /\bformat_html\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'format_html');
    {
        ## <insert tests for format_html method here> ##
    }
}

if ( !$method || $method =~ /\bget_thumbnail_link\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'get_thumbnail_link');
    {
        ## <insert tests for get_thumbnail_link method here> ##
    }
}

if ( !$method || $method =~ /\bget_sol_FK_info\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'get_sol_FK_info');
    {
        ## <insert tests for get_sol_FK_info method here> ##
    }
}

if ( !$method || $method =~ /\bget_TIF_link\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'get_TIF_link');
    {
        ## <insert tests for get_TIF_link method here> ##
    }
}

if ( !$method || $method =~ /\bget_lab_comments\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'get_lab_comments');
    {
        ## <insert tests for get_lab_comments method here> ##
    }
}

if ( !$method || $method =~ /\bstatus_link\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'status_link');
    {
        ## <insert tests for status_link method here> ##
    }
}

if ( !$method || $method =~ /\bdo_actions\b/ ) {
    can_ok("Mapping::Mapping_Summary", 'do_actions');
    {
        ## <insert tests for do_actions method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Mapping_Summary test');

exit;

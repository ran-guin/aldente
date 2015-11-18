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


############################################################
use_ok("UHTS::GCOS_Report_Parser");

if ( !$method || $method =~ /\bresolve_report\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", 'resolve_report');
    {
        ## <insert tests for resolve_report method here> ##
    }
}

if ( !$method || $method =~ /\brewrite_report\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", 'rewrite_report');
    {
        ## <insert tests for rewrite_report method here> ##
    }
}

if ( !$method || $method =~ /\bprocess_report_file\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", 'process_report_file');
    {
        ## <insert tests for process_report_file method here> ##
    }
}

if ( !$method || $method =~ /\blink_report\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", 'link_report');
    {
        ## <insert tests for link_report method here> ##
    }
}

if ( !$method || $method =~ /\bread_report_file\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", 'read_report_file');
    {
        ## <insert tests for read_report_file method here> ##
    }
}

if ( !$method || $method =~ /\bread_expression_file\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", 'read_expression_file');
    {
        ## <insert tests for read_expression_file method here> ##
    }
}

if ( !$method || $method =~ /\bread_mapping_file\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", 'read_mapping_file');
    {
        ## <insert tests for read_mapping_file method here> ##
    }
}

if ( !$method || $method =~ /\b_read_csv_portion\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", '_read_csv_portion');
    {
        ## <insert tests for _read_csv_portion method here> ##
    }
}

if ( !$method || $method =~ /\b_map_to_field\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", '_map_to_field');
    {
        ## <insert tests for _map_to_field method here> ##
    }
}

if ( !$method || $method =~ /\b_find_project_library\b/ ) {
    can_ok("UHTS::GCOS_Report_Parser", '_find_project_library');
    {
        ## <insert tests for _find_project_library method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed GCOS_Report_Parser test');

exit;

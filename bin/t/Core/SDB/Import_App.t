#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

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
use_ok("SDB::Import_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("SDB::Import_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("SDB::Import_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bimport_file\b/ ) {
    can_ok("SDB::Import_App", 'import_file');
    {
        ## <insert tests for import_file method here> ##
    }
}

if ( !$method || $method =~ /\bimport_file_form\b/ ) {
    can_ok("SDB::Import_App", 'import_file_form');
    {
        ## <insert tests for import_file_form method here> ##
    }
}

if ( !$method || $method =~ /\bparse_file\b/ ) {
    can_ok("SDB::Import_App", 'parse_file');
    {
        ## <insert tests for parse_file method here> ##
    }
}

if ( !$method || $method =~ /\bpreview_file\b/ ) {
    can_ok("SDB::Import_App", 'preview_file');
    {
        ## <insert tests for preview_file method here> ##
    }
}

if ( !$method || $method =~ /\bupload_attributes\b/ ) {
    can_ok("SDB::Import_App", 'upload_attributes');
    {
        ## <insert tests for upload_attributes method here> ##
    }
}

if ( !$method || $method =~ /\bextract_data\b/ ) {
    can_ok("SDB::Import_App", 'extract_data');
    {
        ## <insert tests for extract_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_selected_headers\b/ ) {
    can_ok("SDB::Import_App", 'get_selected_headers');
    {
        ## <insert tests for get_selected_headers method here> ##
    }
}


## END of TEST ##

ok( 1 ,'Completed Import_App test');

exit;

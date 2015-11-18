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

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
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
use_ok("SDB::Import_Views");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::Import_Views", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("SDB::Import_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("SDB::Import_Views", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bupload_file_box\b/ ) {
    can_ok("SDB::Import_Views", 'upload_file_box');
    {
        ## <insert tests for upload_file_box method here> ##
    }
}

if ( !$method || $method =~ /\bparse_delimited_file\b/ ) {
    can_ok("SDB::Import_Views", 'parse_delimited_file');
    {
        ## <insert tests for parse_delimited_file method here> ##
    }
}

if ( !$method || $method =~ /\bpreview_DB_update\b/ ) {
    can_ok("SDB::Import_Views", 'preview_DB_update');
    {
        ## <insert tests for preview_DB_update method here> ##
    }
}

if ( !$method || $method =~ /\bget_Detailed_row\b/ ) {
    can_ok("SDB::Import_Views", 'get_Detailed_row');
    {
        ## <insert tests for get_Detailed_row method here> ##
    }
}

if ( !$method || $method =~ /\bpreview_header\b/ ) {
    can_ok("SDB::Import_Views", 'preview_header');
    {
        ## <insert tests for preview_header method here> ##
    }
}

if ( !$method || $method =~ /\bshow_upload_links\b/ ) {
    can_ok("SDB::Import_Views", 'show_upload_links');
    {
        ## <insert tests for show_upload_links method here> ##
    }
}

if ( !$method || $method =~ /\bpreview\b/ ) {
    can_ok("SDB::Import_Views", 'preview');
    {
        ## <insert tests for preview method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Import_Views test');

exit;

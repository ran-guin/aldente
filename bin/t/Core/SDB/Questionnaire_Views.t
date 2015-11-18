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
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;

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
use_ok("SDB::Questionnaire_Views");

if ( !$method || $method =~ /\bdisplay_Save_Form\b/ ) {
    can_ok("SDB::Questionnaire_Views", 'display_Save_Form');
    {
        ## <insert tests for display_Save_Form method here> ##
    }
}

if ( !$method || $method =~ /\bTaxonomy\b/ ) {
    can_ok("SDB::Questionnaire_Views", 'Taxonomy');
    {
        ## <insert tests for Taxonomy method here> ##
    }
}

if ( !$method || $method =~ /\bDisease_types\b/ ) {
    can_ok("SDB::Questionnaire_Views", 'Disease_types');
    {
        ## <insert tests for Disease_types method here> ##
    }
}

if ( !$method || $method =~ /\bXenograft\b/ ) {
    can_ok("SDB::Questionnaire_Views", 'Xenograft');
    {
        ## <insert tests for Xenograft method here> ##
    }
}

if ( !$method || $method =~ /\bsample_type_Page\b/ ) {
    can_ok("SDB::Questionnaire_Views", 'sample_type_Page');
    {
        ## <insert tests for sample_type_Page method here> ##
    }
}

if ( !$method || $method =~ /\bsample_count_Page\b/ ) {
    can_ok("SDB::Questionnaire_Views", 'sample_count_Page');
    {
        ## <insert tests for sample_count_Page method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Questionnaire_Views test');

exit;

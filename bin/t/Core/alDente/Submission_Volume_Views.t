#!/usr/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Submission_Volume_Views;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Submission_Volume_Views");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bsummary_table\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'summary_table');
    {
        ## <insert tests for summary_table method here> ##
    }
}

if ( !$method || $method =~ /\bSubmission_Volume_display_hash\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'Submission_Volume_display_hash');
    {
        ## <insert tests for Submission_Volume_display_hash method here> ##
    }
}

if ( !$method || $method =~ /\bnew_SV_form\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'new_SV_form');
    {
        ## <insert tests for new_SV_form method here> ##
    }
}

if ( !$method || $method =~ /\b_new_SV_form_table\b/ ) {
    can_ok("alDente::Submission_Volume_Views", '_new_SV_form_table');
    {
        ## <insert tests for _new_SV_form_table method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_page\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'display_search_page');
    {
        ## <insert tests for display_search_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_incomplete_Submission_Volume\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'display_incomplete_Submission_Volume');
    {
        ## <insert tests for display_incomplete_Submission_Volume method here> ##
    }
}

if ( !$method || $method =~ /\bparam_summary_table\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'param_summary_table');
    {
        ## <insert tests for param_summary_table method here> ##
    }
}

if ( !$method || $method =~ /\bview_data_submissions\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'view_data_submissions');
    {
        ## <insert tests for view_data_submissions method here> ##
    }
}

if ( !$method || $method =~ /\bdata_submission_summary_page\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'data_submission_summary_page');
    {
        ## <insert tests for data_submission_summary_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_set_accession\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'display_set_accession');
    {
        ## <insert tests for display_set_accession method here> ##
    }
}

if ( !$method || $method =~ /\bget_study_page\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'get_study_page');
    {
        ## <insert tests for get_study_page method here> ##
    }
}

if ( !$method || $method =~ /\bget_submission_views\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'get_submission_views');
    {
        ## <insert tests for get_submission_views method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_summary_page\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'display_summary_page');
    {
        ## <insert tests for display_summary_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_new_submission_volume_custom_confirm_page\b/ ) {
    can_ok("alDente::Submission_Volume_Views", 'display_new_submission_volume_custom_confirm_page');
    {
        ## <insert tests for display_new_submission_volume_custom_confirm_page method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Submission_Volume_Views test');

exit;

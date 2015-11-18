#!/usr/local/bin/perl
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
use alDente::Submission;
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




use_ok("alDente::Submission");

my $self = new alDente::Submission(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Submission", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_full_table\b/ ) {
    can_ok("alDente::Submission", 'display_full_table');
    {
        ## <insert tests for display_full_table method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_simple_submission_table\b/ ) {
    can_ok("alDente::Submission", 'display_simple_submission_table');
    {
        ## <insert tests for display_simple_submission_table method here> ##
    }
}

if ( !$method || $method=~/\bmicroarray_submission_file_presets\b/ ) {
    can_ok("alDente::Submission", 'microarray_submission_file_presets');
    {
        ## <insert tests for microarray_submission_file_presets method here> ##
    }
}

if ( !$method || $method=~/\binsert_submission_file\b/ ) {
    can_ok("alDente::Submission", 'insert_submission_file');
    {
        ## <insert tests for insert_submission_file method here> ##
    }
}

#if ( !$method || $method=~/\bdisplay_submission_search_form\b/ ) {
#    can_ok("alDente::Submission", 'display_submission_search_form');
#    {
#        ## <insert tests for display_submission_search_form method here> ##
#        my $submission_obj = self();
#        my $groups         = [3,18];
#
#        ## create submission search form
#        my $submission_search_form =  $submission_obj->display_submission_search_form(-groups=>$groups);
#
#        is ($submission_search_form->{toggle_colour}, 0, "Check if the search form is created, toggle colour is off");
#        
#    }
#}

## END of TEST ##

ok( 1 ,'Completed Submission test');

exit;

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
use alDente::Help;
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




use_ok("alDente::Help");

if ( !$method || $method=~/\bSDB_help\b/ ) {
    can_ok("alDente::Help", 'SDB_help');
    {
        ## <insert tests for SDB_help method here> ##
    }
}

if ( !$method || $method=~/\bHelp_Links\b/ ) {
    can_ok("alDente::Help", 'Help_Links');
    {
        ## <insert tests for Help_Links method here> ##
    }
}

if ( !$method || $method=~/\bLogin_Help\b/ ) {
    can_ok("alDente::Help", 'Login_Help');
    {
        ## <insert tests for Login_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_01_01_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_01_01_Help');
    {
        ## <insert tests for Revision_2001_01_01_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2002_02_18_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2002_02_18_Help');
    {
        ## <insert tests for Revision_2002_02_18_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_10_16_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_10_16_Help');
    {
        ## <insert tests for Revision_2001_10_16_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_09_24_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_09_24_Help');
    {
        ## <insert tests for Revision_2001_09_24_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_09_10_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_09_10_Help');
    {
        ## <insert tests for Revision_2001_09_10_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_08_13_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_08_13_Help');
    {
        ## <insert tests for Revision_2001_08_13_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_07_30_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_07_30_Help');
    {
        ## <insert tests for Revision_2001_07_30_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_07_16_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_07_16_Help');
    {
        ## <insert tests for Revision_2001_07_16_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_07_03_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_07_03_Help');
    {
        ## <insert tests for Revision_2001_07_03_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_06_18_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_06_18_Help');
    {
        ## <insert tests for Revision_2001_06_18_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_06_04_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_06_04_Help');
    {
        ## <insert tests for Revision_2001_06_04_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_05_21_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_05_21_Help');
    {
        ## <insert tests for Revision_2001_05_21_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_05_07_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_05_07_Help');
    {
        ## <insert tests for Revision_2001_05_07_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_04_23_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_04_23_Help');
    {
        ## <insert tests for Revision_2001_04_23_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_04_02_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_04_02_Help');
    {
        ## <insert tests for Revision_2001_04_02_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_03_19_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_03_19_Help');
    {
        ## <insert tests for Revision_2001_03_19_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_03_05_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_03_05_Help');
    {
        ## <insert tests for Revision_2001_03_05_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_02_12_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_02_12_Help');
    {
        ## <insert tests for Revision_2001_02_12_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_02_05_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_02_05_Help');
    {
        ## <insert tests for Revision_2001_02_05_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_2001_01_22_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_2001_01_22_Help');
    {
        ## <insert tests for Revision_2001_01_22_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_Help\b/ ) {
    can_ok("alDente::Help", 'Revision_Help');
    {
        ## <insert tests for Revision_Help method here> ##
    }
}

if ( !$method || $method=~/\bRevision_Help_Old\b/ ) {
    can_ok("alDente::Help", 'Revision_Help_Old');
    {
        ## <insert tests for Revision_Help_Old method here> ##
    }
}

if ( !$method || $method=~/\bSummary_Help\b/ ) {
    can_ok("alDente::Help", 'Summary_Help');
    {
        ## <insert tests for Summary_Help method here> ##
    }
}

if ( !$method || $method=~/\bIcons_Help\b/ ) {
    can_ok("alDente::Help", 'Icons_Help');
    {
        ## <insert tests for Icons_Help method here> ##
    }
}

if ( !$method || $method=~/\bOnline_help\b/ ) {
    can_ok("alDente::Help", 'Online_help');
    {
        ## <insert tests for Online_help method here> ##
    }
}

if ( !$method || $method=~/\bOnline_help_search\b/ ) {
    can_ok("alDente::Help", 'Online_help_search');
    {
        ## <insert tests for Online_help_search method here> ##
    }
}

if ( !$method || $method=~/\bOnline_help_search_results\b/ ) {
    can_ok("alDente::Help", 'Online_help_search_results');
    {
        ## <insert tests for Online_help_search_results method here> ##
    }
}

if ( !$method || $method=~/\bOH_Main_Flow\b/ ) {
    can_ok("alDente::Help", 'OH_Main_Flow');
    {
        ## <insert tests for OH_Main_Flow method here> ##
    }
}

if ( !$method || $method=~/\bOH_Phred_Analysis\b/ ) {
    can_ok("alDente::Help", 'OH_Phred_Analysis');
    {
        ## <insert tests for OH_Phred_Analysis method here> ##
    }
}

if ( !$method || $method=~/\bOH_Solution_Flow\b/ ) {
    can_ok("alDente::Help", 'OH_Solution_Flow');
    {
        ## <insert tests for OH_Solution_Flow method here> ##
    }
}

if ( !$method || $method=~/\bOH_Rearray_definitions\b/ ) {
    can_ok("alDente::Help", 'OH_Rearray_definitions');
    {
        ## <insert tests for OH_Rearray_definitions method here> ##
    }
}

if ( !$method || $method=~/\bOH_Mixing_solutions\b/ ) {
    can_ok("alDente::Help", 'OH_Mixing_solutions');
    {
        ## <insert tests for OH_Mixing_solutions method here> ##
    }
}

if ( !$method || $method=~/\bOH_new_reagents\b/ ) {
    can_ok("alDente::Help", 'OH_new_reagents');
    {
        ## <insert tests for OH_new_reagents method here> ##
    }
}

if ( !$method || $method=~/\bOH_new_plates\b/ ) {
    can_ok("alDente::Help", 'OH_new_plates');
    {
        ## <insert tests for OH_new_plates method here> ##
    }
}

if ( !$method || $method=~/\bOH_new_libraries\b/ ) {
    can_ok("alDente::Help", 'OH_new_libraries');
    {
        ## <insert tests for OH_new_libraries method here> ##
    }
}

if ( !$method || $method=~/\bOH_new_projects\b/ ) {
    can_ok("alDente::Help", 'OH_new_projects');
    {
        ## <insert tests for OH_new_projects method here> ##
    }
}

if ( !$method || $method=~/\bOH_making_changes\b/ ) {
    can_ok("alDente::Help", 'OH_making_changes');
    {
        ## <insert tests for OH_making_changes method here> ##
    }
}

if ( !$method || $method=~/\bOH_deleting_mistakes\b/ ) {
    can_ok("alDente::Help", 'OH_deleting_mistakes');
    {
        ## <insert tests for OH_deleting_mistakes method here> ##
    }
}

if ( !$method || $method=~/\bOH_making_notes\b/ ) {
    can_ok("alDente::Help", 'OH_making_notes');
    {
        ## <insert tests for OH_making_notes method here> ##
    }
}

if ( !$method || $method=~/\bOH_Stock_Help\b/ ) {
    can_ok("alDente::Help", 'OH_Stock_Help');
    {
        ## <insert tests for OH_Stock_Help method here> ##
    }
}

if ( !$method || $method=~/\bOH_ReArray_Help\b/ ) {
    can_ok("alDente::Help", 'OH_ReArray_Help');
    {
        ## <insert tests for OH_ReArray_Help method here> ##
    }
}

if ( !$method || $method=~/\bOH_Scanner_Help\b/ ) {
    can_ok("alDente::Help", 'OH_Scanner_Help');
    {
        ## <insert tests for OH_Scanner_Help method here> ##
    }
}

if ( !$method || $method=~/\bOH_ReBooting\b/ ) {
    can_ok("alDente::Help", 'OH_ReBooting');
    {
        ## <insert tests for OH_ReBooting method here> ##
    }
}

if ( !$method || $method=~/\bOH_Protocol_Formats\b/ ) {
    can_ok("alDente::Help", 'OH_Protocol_Formats');
    {
        ## <insert tests for OH_Protocol_Formats method here> ##
    }
}

if ( !$method || $method=~/\bOH_Manual_Analysis\b/ ) {
    can_ok("alDente::Help", 'OH_Manual_Analysis');
    {
        ## <insert tests for OH_Manual_Analysis method here> ##
    }
}

if ( !$method || $method=~/\bOH_Debugging_Errors\b/ ) {
    can_ok("alDente::Help", 'OH_Debugging_Errors');
    {
        ## <insert tests for OH_Debugging_Errors method here> ##
    }
}

if ( !$method || $method=~/\bOH_DB_Modules\b/ ) {
    can_ok("alDente::Help", 'OH_DB_Modules');
    {
        ## <insert tests for OH_DB_Modules method here> ##
    }
}

if ( !$method || $method=~/\bOH_Restoring_Database\b/ ) {
    can_ok("alDente::Help", 'OH_Restoring_Database');
    {
        ## <insert tests for OH_Restoring_Database method here> ##
    }
}

if ( !$method || $method=~/\bOH_Slow_Response_Time\b/ ) {
    can_ok("alDente::Help", 'OH_Slow_Response_Time');
    {
        ## <insert tests for OH_Slow_Response_Time method here> ##
    }
}

if ( !$method || $method=~/\bOH_Chemistry_Calculator\b/ ) {
    can_ok("alDente::Help", 'OH_Chemistry_Calculator');
    {
        ## <insert tests for OH_Chemistry_Calculator method here> ##
    }
}

if ( !$method || $method=~/\bOH_New_Sequencer\b/ ) {
    can_ok("alDente::Help", 'OH_New_Sequencer');
    {
        ## <insert tests for OH_New_Sequencer method here> ##
    }
}

if ( !$method || $method=~/\bOH_Sample_Sheets\b/ ) {
    can_ok("alDente::Help", 'OH_Sample_Sheets');
    {
        ## <insert tests for OH_Sample_Sheets method here> ##
    }
}

if ( !$method || $method=~/\bOH_Directories\b/ ) {
    can_ok("alDente::Help", 'OH_Directories');
    {
        ## <insert tests for OH_Directories method here> ##
    }
}

if ( !$method || $method=~/\bOH_Command_Line_Scripts\b/ ) {
    can_ok("alDente::Help", 'OH_Command_Line_Scripts');
    {
        ## <insert tests for OH_Command_Line_Scripts method here> ##
    }
}

if ( !$method || $method=~/\bWarnings_Help\b/ ) {
    can_ok("alDente::Help", 'Warnings_Help');
    {
        ## <insert tests for Warnings_Help method here> ##
    }
}

if ( !$method || $method=~/\bOH_Module_Routines\b/ ) {
    can_ok("alDente::Help", 'OH_Module_Routines');
    {
        ## <insert tests for OH_Module_Routines method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Help test');

exit;

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
use alDente::Issue;
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




use_ok("alDente::Issue");

my $self = new alDente::Issue(-dbc=>$dbc);
if ( !$method || $method=~/\bIssues_Home\b/ ) {
    can_ok("alDente::Issue", 'Issues_Home');
    {
        ## <insert tests for Issues_Home() method here> ##
    }
}

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Issue", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Issue", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\b_issue_requirements\b/ ) {
    can_ok("alDente::Issue", '_issue_requirements');
    {
        ## <insert tests for _issue_requirements method here> ##
    }
}

if ( !$method || $method=~/\b_deferred_Issues\b/ ) {
    can_ok("alDente::Issue", '_deferred_Issues');
    {
        ## <insert tests for _deferred_Issues method here> ##
    }
}

if ( !$method || $method=~/\bSearch_Issues\b/ ) {
    can_ok("alDente::Issue", 'Search_Issues');
    {
        ## <insert tests for Search_Issues() method here> ##
    }
}

if ( !$method || $method=~/\b_edit_Issue\b/ ) {
    can_ok("alDente::Issue", '_edit_Issue');
    {
        ## <insert tests for _edit_Issue() method here> ##
    }
}

if ( !$method || $method=~/\bAdd_Issue\b/ ) {
    can_ok("alDente::Issue", 'Add_Issue');
    {
        ## <insert tests for Add_Issue() method here> ##
    }
}

if ( !$method || $method=~/\b_send_email\b/ ) {
    can_ok("alDente::Issue", '_send_email');
    {
        ## <insert tests for _send_email method here> ##
    }
}

if ( !$method || $method=~/\b_ongoing_maintenance\b/ ) {
    can_ok("alDente::Issue", '_ongoing_maintenance');
    {
        ## <insert tests for _ongoing_maintenance method here> ##
    }
}

if ( !$method || $method=~/\bWorkLog\b/ ) {
    can_ok("alDente::Issue", 'WorkLog');
    {
        ## <insert tests for WorkLog method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Issue_trigger\b/ ) {
    can_ok("alDente::Issue", 'update_Issue_trigger');
    {
        ## <insert tests for update_Issue_trigger method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Issue_from_WorkLog\b/ ) {
    can_ok("alDente::Issue", 'update_Issue_from_WorkLog');
    {
        ## <insert tests for update_Issue_from_WorkLog method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Issue_from_WorkLog_helper\b/ ) {
    can_ok("alDente::Issue", 'update_Issue_from_WorkLog_helper');
    {
        ## <insert tests for update_Issue_from_WorkLog_helper method here> ##
    }
}

if ( !$method || $method=~/\btime_spent_on_children\b/ ) {
    can_ok("alDente::Issue", 'time_spent_on_children');
    {
        ## <insert tests for time_spent_on_children method here> ##
    }
}

if ( !$method || $method=~/\b_closed_issue_notification\b/ ) {
    can_ok("alDente::Issue", '_closed_issue_notification');
    {
        ## <insert tests for _closed_issue_notification method here> ##
    }
}

if ( !$method || $method=~/\bemail_list\b/ ) {
    can_ok("alDente::Issue", 'email_list');
    {
        ## <insert tests for email_list method here> ##
    }
}

if ( !$method || $method=~/\b_generate_StatusReport\b/ ) {
    can_ok("alDente::Issue", '_generate_StatusReport');
    {
        ## <insert tests for _generate_StatusReport method here> ##
    }
}

if ( !$method || $method=~/\bAssign_Issue\b/ ) {
    can_ok("alDente::Issue", 'Assign_Issue');
    {
        ## <insert tests for Assign_Issue method here> ##
    }
}

if ( !$method || $method=~/\bsave_StatusReport\b/ ) {
    can_ok("alDente::Issue", 'save_StatusReport');
    {
        ## <insert tests for save_StatusReport method here> ##
    }
}

if ( !$method || $method=~/\bcustom_cells\b/ ) {
    can_ok("alDente::Issue", 'custom_cells');
    {
        ## <insert tests for custom_cells method here> ##
    }
}

if ( !$method || $method=~/\bnew_Package\b/ ) {
    can_ok("alDente::Issue", 'new_Package');
    {
        ## <insert tests for new_Package method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_Requirements\b/ ) {
    can_ok("alDente::Issue", 'generate_Requirements');
    {
        ## <insert tests for generate_Requirements method here> ##
    }
}

if ( !$method || $method=~/\bUpdate_Issue\b/ ) {
    can_ok("alDente::Issue", 'Update_Issue');
    {
        ## <insert tests for Update_Issue method here> ##
    }
}

if ( !$method || $method=~/\bView_Issue_Log\b/ ) {
    can_ok("alDente::Issue", 'View_Issue_Log');
    {
        ## <insert tests for View_Issue_Log       method here> ##
    }
}

if ( !$method || $method=~/\bgraph_Work\b/ ) {
    can_ok("alDente::Issue", 'graph_Work');
    {
        ## <insert tests for graph_Work method here> ##
    }
}

if ( !$method || $method=~/\bView_All_Issue_Stats\b/ ) {
    can_ok("alDente::Issue", 'View_All_Issue_Stats');
    {
        ## <insert tests for View_All_Issue_Stats method here> ##
    }
}

if ( !$method || $method=~/\b_correct_estimates\b/ ) {
    can_ok("alDente::Issue", '_correct_estimates');
    {
        ## <insert tests for _correct_estimates method here> ##
    }
}

if ( !$method || $method=~/\b_print_issue_info\b/ ) {
    can_ok("alDente::Issue", '_print_issue_info');
    {
        ## <insert tests for _print_issue_info method here> ##
    }
}

if ( !$method || $method=~/\b_open_work\b/ ) {
    can_ok("alDente::Issue", '_open_work');
    {
        ## <insert tests for _open_work method here> ##
    }
}

if ( !$method || $method=~/\bmaintain_Issues\b/ ) {
    can_ok("alDente::Issue", 'maintain_Issues');
    {
        ## <insert tests for maintain_Issues method here> ##
    }
}

if ( !$method || $method=~/\b_admin_log\b/ ) {
    can_ok("alDente::Issue", '_admin_log');
    {
        ## <insert tests for _admin_log method here> ##
    }
}

if ( !$method || $method=~/\b_print_issue_stats\b/ ) {
    can_ok("alDente::Issue", '_print_issue_stats');
    {
        ## <insert tests for _print_issue_stats method here> ##
    }
}

if ( !$method || $method=~/\b_print_work_package_stats\b/ ) {
    can_ok("alDente::Issue", '_print_work_package_stats');
    {
        ## <insert tests for _print_work_package_stats method here> ##
    }
}

if ( !$method || $method=~/\b_group_packages\b/ ) {
    can_ok("alDente::Issue", '_group_packages');
    {
        ## <insert tests for _group_packages method here> ##
    }
}

if ( !$method || $method=~/\b_print_status_report_form\b/ ) {
    can_ok("alDente::Issue", '_print_status_report_form');
    {
        ## <insert tests for _print_status_report_form method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_work_summary\b/ ) {
    can_ok("alDente::Issue", 'generate_work_summary');
    {
        ## <insert tests for generate_work_summary method here> ##
    }
}

if ( !$method || $method=~/\bget_work_summary_stats\b/ ) {
    can_ok("alDente::Issue", 'get_work_summary_stats');
    {
        ## <insert tests for get_work_summary_stats method here> ##
    }
}

if ( !$method || $method=~/\b_generate_report\b/ ) {
    can_ok("alDente::Issue", '_generate_report');
    {
        ## <insert tests for _generate_report method here> ##
    }
}

if ( !$method || $method=~/\b_generate_report_helper\b/ ) {
    can_ok("alDente::Issue", '_generate_report_helper');
    {
        ## <insert tests for _generate_report_helper method here> ##
    }
}

if ( !$method || $method=~/\b_show_child_issues\b/ ) {
    can_ok("alDente::Issue", '_show_child_issues');
    {
        ## <insert tests for _show_child_issues method here> ##
    }
}

if ( !$method || $method=~/\b_issue_link\b/ ) {
    can_ok("alDente::Issue", '_issue_link');
    {
        ## <insert tests for _issue_link method here> ##
    }
}

if ( !$method || $method=~/\b_set_Issue_Version\b/ ) {
    can_ok("alDente::Issue", '_set_Issue_Version');
    {
        ## <insert tests for _set_Issue_Version method here> ##
    }
}

if ( !$method || $method=~/\b_defer_Issue\b/ ) {
    can_ok("alDente::Issue", '_defer_Issue');
    {
        ## <insert tests for _defer_Issue method here> ##
    }
}

if ( !$method || $method=~/\b_show_package\b/ ) {
    can_ok("alDente::Issue", '_show_package');
    {
        ## <insert tests for _show_package method here> ##
    }
}

if ( !$method || $method=~/\bcalculate_summary_values\b/ ) {
    can_ok("alDente::Issue", 'calculate_summary_values');
    {
        ## <insert tests for calculate_summary_values method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Issue test');

exit;

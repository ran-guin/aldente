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
use alDente::Submission_App;
############################

############################################


use_ok("alDente::Submission_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Submission_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bdefault_page\b/ ) {
    can_ok("alDente::Submission_App", 'default_page');
    {
        ## <insert tests for default_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_employee_requests\b/ ) {
    can_ok("alDente::Submission_App", 'display_employee_requests');
    {
        ## <insert tests for display_employee_requests method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_work_request_button\b/ ) {
    can_ok("alDente::Submission_App", 'display_work_request_button');
    {
        ## <insert tests for display_work_request_button method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_submission_search_form\b/ ) {
    can_ok("alDente::Submission_App", 'display_submission_search_form');
    {
        ## <insert tests for display_submission_search_form method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_submission\b/ ) {
    can_ok("alDente::Submission_App", 'search_submission');
    {
        ## <insert tests for search_submission method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_submissions\b/ ) {
    can_ok("alDente::Submission_App", 'check_submissions');
    {
        ## <insert tests for check_submissions method here> ##
    }
}

if ( !$method || $method =~ /\bsave_as_new_submission\b/ ) {
    can_ok("alDente::Submission_App", 'save_as_new_submission');
    {
        ## <insert tests for save_as_new_submission method here> ##
    }
}

if ( !$method || $method =~ /\bactivate_submission\b/ ) {
    can_ok("alDente::Submission_App", 'activate_submission');
    {
        ## <insert tests for activate_submission method here> ##
    }
}

if ( !$method || $method =~ /\bcomplete_submission\b/ ) {
    can_ok("alDente::Submission_App", 'complete_submission');
    {
        ## <insert tests for complete_submission method here> ##
    }
}

if ( !$method || $method =~ /\breject_submission\b/ ) {
    can_ok("alDente::Submission_App", 'reject_submission');
    {
        ## <insert tests for reject_submission method here> ##
    }
}

if ( !$method || $method =~ /\bcancel_submission\b/ ) {
    can_ok("alDente::Submission_App", 'cancel_submission');
    {
        ## <insert tests for cancel_submission method here> ##
    }
}

if ( !$method || $method =~ /\bapprove_submission\b/ ) {
    can_ok("alDente::Submission_App", 'approve_submission');
    {
        ## <insert tests for approve_submission method here> ##
    }
}

if ( !$method || $method =~ /\bsubmit_draft\b/ ) {
    can_ok("alDente::Submission_App", 'submit_draft');
    {
        ## <insert tests for submit_draft method here> ##
    }
}

if ( !$method || $method =~ /\bedit_submission\b/ ) {
    can_ok("alDente::Submission_App", 'edit_submission');
    {
        ## <insert tests for edit_submission method here> ##
    }
}

if ( !$method || $method =~ /\bsubmission_action_handler\b/ ) {
    can_ok("alDente::Submission_App", 'submission_action_handler');
    {
        ## <insert tests for submission_action_handler method here> ##
    }
}

if ( !$method || $method =~ /\bwork_request_information\b/ ) {
    can_ok("alDente::Submission_App", 'work_request_information');
    {
        ## <insert tests for work_request_information method here> ##
    }
}

if ( !$method || $method =~ /\bnew_work_request\b/ ) {
    can_ok("alDente::Submission_App", 'new_work_request');
    {
        ## <insert tests for new_work_request method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_new_library\b/ ) {
    can_ok("alDente::Submission_App", 'create_new_library');
    {
        ## <insert tests for create_new_library method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_new_source\b/ ) {
    can_ok("alDente::Submission_App", 'create_new_source');
    {
        ## <insert tests for create_new_source method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_external_submission_form\b/ ) {
    can_ok("alDente::Submission_App", 'generate_external_submission_form');
    {
        ## <insert tests for generate_external_submission_form method here> ##
    }
}

if ( !$method || $method =~ /\bView_Submission\b/ ) {
    can_ok("alDente::Submission_App", 'View_Submission');
    {
        ## <insert tests for View_Submission method here> ##
    }
}

if ( !$method || $method =~ /\bview_edit_submission_info\b/ ) {
    can_ok("alDente::Submission_App", 'view_edit_submission_info');
    {
        ## <insert tests for view_edit_submission_info method here> ##
    }
}

if ( !$method || $method =~ /\bsubmit_as_resubmission\b/ ) {
    can_ok("alDente::Submission_App", 'submit_as_resubmission');
    {
        ## <insert tests for submit_as_resubmission method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_copy_submission_for_new_library_button\b/ ) {
    can_ok("alDente::Submission_App", 'display_copy_submission_for_new_library_button');
    {
        ## <insert tests for display_copy_submission_for_new_library_button method here> ##
    }
}

if ( !$method || $method =~ /\bcopy_submission_for_new_library\b/ ) {
    can_ok("alDente::Submission_App", 'copy_submission_for_new_library');
    {
        ## <insert tests for copy_submission_for_new_library method here> ##
    }
}

########################
## Add Run Mode Tests ##
########################
my $page;    ## output from respective run mode (Use RGTools::Unit_Test methods to check for output tables etc)
=begin
### Completed ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Completed', -Params=> {});

### Delete Submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Delete Submission', -Params=> {});

### Save As a New Submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Save As a New Submission', -Params=> {});

### Submission Action ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Submission Action', -Params=> {});

### View ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'View', -Params=> {});

### Create New Library ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Create New Library', -Params=> {});

### Review and Submit Draft ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Review and Submit Draft', -Params=> {});

### Check Submissions ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Check Submissions', -Params=> {});

### Edit submission as a re-submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Edit submission as a re-submission', -Params=> {});

### Cancel ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Cancel', -Params=> {});

### Delete ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Delete', -Params=> {});

### Edit ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Edit', -Params=> {});

### Submit Draft ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Submit Draft', -Params=> {});

### Attach File ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Attach File', -Params=> {});

### Reject Submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Reject Submission', -Params=> {});

### Submit Sequencing Work Request ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Submit Sequencing Work Request', -Params=> {});

### Approve ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Approve', -Params=> {});

### Search Submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Search Submission', -Params=> {});

### Copy Submission for New Library ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Copy Submission for New Library', -Params=> {});

### Add New Contact ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Add New Contact', -Params=> {});

### Cancel Submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Cancel Submission', -Params=> {});

### Reject ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Reject', -Params=> {});

### Approve Submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Approve Submission', -Params=> {});

### Add New User ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Add New User', -Params=> {});

### SubmitDraft ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'SubmitDraft', -Params=> {});

### Completed Submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Completed Submission', -Params=> {});

### Copy Submission for a New Library ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Copy Submission for a New Library', -Params=> {});

### Activate cancelled submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Activate cancelled submission', -Params=> {});

### Submit Work Request ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Submit Work Request', -Params=> {});

### View/Edit Submission Info ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'View/Edit Submission Info', -Params=> {});

### Activate ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Activate', -Params=> {});

### Default Page ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Default Page', -Params=> {});

### SaveAsNew ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'SaveAsNew', -Params=> {});

### Edit submission ###
$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::Submission_App',-rm=>'Edit submission', -Params=> {});

## END of TEST ##
=cut
ok( 1 ,'Completed Submission_App test');

exit;

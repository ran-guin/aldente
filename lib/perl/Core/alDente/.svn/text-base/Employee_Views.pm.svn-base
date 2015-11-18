##############################################################################################
# alDente::Employee_Views.pm
#
# Interface generating methods for the Employee MVC  (assoc with Employee.pm, Employee_App.pm)
#
##############################################################################################
package alDente::Employee_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;

use alDente::Form;
use alDente::Employee;

## globals ##
use vars qw( %Configs );

my $q = new CGI;
###################################
#
###################################
sub set_Employee_Groups {
###################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my @employee_list = $dbc->get_FK_info( -field => 'FK_Employee__ID', -list => 1 );
    my $lims_column .= section_heading("Set Employee Group Membership") . alDente::Tools::search_list( -table => 'Employee', -field => 'FK_Employee__ID', -search => 1, -filter => 1 )

        #        . $q->popup_menu( -name => 'Employee_Name', -values => [ '-- select user --', @employee_list ], -default => '-- select user --', -force => 1 )
        . $q->submit( -name => 'rm', -label => 'Establish Groups', -class => "Std", -force => 1 ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Employee_App', -force => 1 );

    return alDente::Form::start_alDente_form( $dbc, 'users' ) . $lims_column . $q->end_form();
}

###################################
#
###################################
sub display_employee_requests {
###################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $Employee = new alDente::Employee( -dbc => $dbc );

    my $groups = $Employee->get_employee_Groups( -dbc => $dbc );
    Message "Please Approve/Edit/Cancel/Reject employee requests from the table below. Or click on the Submission ID for more information and options.";

    require alDente::Submission_Views;
    my $submission_views = new alDente::Submission_Views( -dbc => $dbc );

    my $form = $submission_views->check_submissions(
        -dbc       => $dbc,
        -status    => 'Submitted',
        -groups    => $groups,
        -form_name => 'Employee Requests',
        -table     => 'Employee'
    );
    return $form;
}

###################################
#
###################################
sub display_Group_Selection {
###################################
    my $self     = shift;
    my %args     = @_;
    my $employee = $args{-employee};
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $emp_id   = &get_FK_ID( $dbc, "FK_Employee__ID", $employee );
    my $emp_name = &get_FK_info( -dbc => $dbc, -field => 'FK_Employee__ID', -id => $emp_id );

    my $Employee = new alDente::Employee( -dbc => $dbc );
    my $groups = $Employee->get_employee_Groups( -dbc => $dbc, -admin => 1 );

    my $edit   = 0;                        ## flag to indicate whether group list may be edited by current user ##
    my $access = $dbc->config('groups');
    if ( $access && grep /Admin/i, @$access ) { $edit = 1 }

    return $self->join_records(
        -dbc        => $dbc,
        -defined    => "FK_Employee__ID",
        -id         => $emp_id,
        -join       => 'FK_Grp__ID',
        -join_table => "GrpEmployee",
        -filter     => "Grp_Status = 'Active' AND Grp_ID IN ($groups)",
        -table      => 'Employee',
        -title      => "Group Membership for $emp_name",
        -edit       => $edit
    );
}

####################
sub object_label {
####################
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my $user_id = $dbc->get_local('user_id');

    my $Object = $self->Model();

    my $label = "<B>" . $Object->value('Employee_FullName') . " (" . $Object->value('Employee.Employee_Name') . ")</B>";
    $label .= "<BR>[EMP$user_id]";
    $label .= "<BR>Position: " . $Object->value('Employee.Position') . '<BR><BR>';

    if ( $Object->value('Employee.FK_Department__ID') ) {
        ## Indicate Department if it is defined ##
        my $department_name = get_FK_info( $dbc, 'FK_Department__ID', $Object->value('Employee.FK_Department__ID') );
        $label .= " ($department_name)<BR>";
    }

    return $label;
}

############################
sub display_record_page {
#############################
    my $self    = shift;
    my %args    = filter_input( \@_, -args => 'Object' );
    my $Object  = $args{-Employee} || $args{-Object} || $self->Model();    ## not necessary ...
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $user_id = $args{-id} || $self->{id};

    ### Show Grp Membership ##
    my $edit      = 0;                                                     ## flag to indicate if current user has admin access to edit groups (Note: department level access is accounted for and limited to the filtered options within join_records)
    my $condition = "Grp_Status = 'Active'";
    my $access    = $dbc->config('groups');
    if ( $access && grep /Admin/i, @$access ) {
        my $groups = alDente::Employee->get_employee_Groups( -dbc => $dbc, -admin => 1 );
        $condition .= " AND Grp_ID IN ($groups)";
        $edit = 1;
    }

    my $options = $self->join_records( -dbc => $dbc, -defined => "FK_Employee__ID", -id => $user_id, -join => 'FK_Grp__ID', -join_table => "GrpEmployee", -filter => $condition, -table => 'Employee', -title => "Group Membership", -edit => $edit );

    return $self->SUPER::display_record_page(
        -layers          => $options,                                      ## if only one layer, this parameter can be a static value - otherwise supply standard layers array ##
        -record_position => 'right',                                       ## display database record dump on right side of screen (uses split_page_format)
        -right           => '',                                            ## define right to reduce span of label (which would otherwise span full width by default)
    );

}

return 1;

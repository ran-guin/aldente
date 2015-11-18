####################
# Submission_Volume_Views.pm #
####################
#
# This contains various Submission Volume view pages:
#

package alDente::Submission_Volume_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw( :standard );

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::Web_Form;
use RGTools::RGmath;

use alDente::SDB_Defaults;
use alDente::Tools;
use alDente::Submission_Volume;

## globals ##
use vars qw( %Configs );

#**************************
#**************************
############################################
# constructor
############################################
sub new {
############################################
    my $this  = shift;
    my %args  = filter_input( \@_ );
    my $model = $args{-model};
    my $dbc   = $args{-dbc};

    my $self = {};
    my ($class) = ref $this || $this;
    bless $self, $class;
    $self->{dbc}   = $dbc;
    $self->{Model} = $model;

    return $self;
}

=begin



##############
##############
# Moved in SRA::Data_Submission MVC
###############
###############



############################################
#
# Home page for submission volume
#
############################################
sub home_page {
###########################
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $volume_ids = $args{-id};

    my @volume_id_array = Cast_List( -list => $volume_ids, -to => 'Array' );
    unless (@volume_id_array) { return display_search_page( -dbc => $dbc ) }

    my $output = "";
    my %colspan;
    $colspan{1}->{1} = 2;    ## set the Heading to span 2 columns

    foreach my $volume_id (@volume_id_array) {
        my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
        my $volume_info = $volume_obj->get_volume_info( -dbc => $dbc, -id => $volume_id );
        if ( !$volume_info || !defined $volume_info->{Volume_Name} ) {
            Message("WARNING: Volume id $volume_id missing required volume information\n");
            next;
        }

        my $left_col;
        my $left_form_name = "Volume_Info";
        $left_col = alDente::Form::start_alDente_form(-dbc=>$dbc, -name=>$left_form_name);
        $left_col .= hidden( -name => 'cgi_application',      -value => 'alDente::Submission_Volume_App' );
        $left_col .= hidden( -name => 'Submission_Volume_ID', -value => $volume_id );
        $left_col .= $self->display_volume_info( -volume_info => $volume_info );
        $left_col .= $self->display_meta_action_button(
            -dbc         => $dbc,
            -volume_info => $volume_info,
            -form_name   => $left_form_name
        );
        $left_col .= end_form();

        my @fields = ( "Trace_Submission_ID", "Run_ID", "Submission_Status", "Run_Directory", "Run_DateTime", "Flowcell_Code as Flowcell", "Lane", "SolexaRun_Type", "FK_Sample__ID as Sample", );
        my $run_info = $volume_obj->get_submission_run_info( -dbc => $dbc, -volume_id => $volume_id );

        my $right_col;
        my $right_form_name = "Submission_Run_Info";
        $right_col .= alDente::Form::start_alDente_form(-dbc=>$dbc, -name=>$right_form_name);
        $right_col .= hidden( -name => 'cgi_application', -value => 'alDente::Submission_Volume_App' );
        $right_col .= hidden( -name => 'Submission_Volume_ID', -value => $volume_id );
        my $tables = "Trace_Submission,Run ";
        $tables    .= " LEFT JOIN SolexaRun ON SolexaRun.FK_Run__ID = Run_ID ";
        $tables    .= " LEFT JOIN Flowcell ON FK_Flowcell__ID = Flowcell_ID ";
        $right_col .= $dbc->Table_retrieve_display(
            -title            => "Run Data Submission: $volume_info->{Volume_Name}",
            -return_html      => 1,
            -table            => $tables,
            -fields           => \@fields,
            -selectable_field => "Trace_Submission_ID",
            -condition        => "WHERE FK_Submission_Volume__ID = $volume_id and Trace_Submission.FK_Run__ID = Run_ID",
            -order            => 'Submission_Status,Flowcell,Lane',
        );
        $right_col .= $self->display_run_action_button(
            -dbc       => $dbc,
            -run_info  => $run_info,
            -form_name => $right_form_name
        );

        $output .= &Views::Heading("Submission_Volume: $volume_info->{Volume_Name}");
        $output .= &Views::Table_Print(
            content => [ [ $left_col, $right_col ] ],
            spacing => 5,
            colspan => \%colspan,
            print   => 0
        );
    }
    return $output;
}
=cut

#***********************
#************************
############################################
#
# Display Submission Volume information
#
############################################
sub summary_table {
############################################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $volume_data = $args{-volume_data} || {};
    my $field_order = $args{-field_order} || keys %$volume_data;
    my $dbc         = $args{-dbc} || $self->{dbc};

    my $volume_name = Cast_List( -to => 'string', -list => $volume_data->{"Submission_Volume.Volume_Name"} ) || "Unknown name";

    my $table = HTML_Table->new(
        -width  => 300,
        -border => 1,
        -title  => "Submission_Volume: " . $volume_name,
    );
    $table->Toggle_Colour('off');
    $table->Set_Padding(0);
    $table->Set_Line_Colour("#FFFFFF");

    foreach my $field (@$field_order) {
        my $value = Cast_List( -to => 'string', -list => $volume_data->{$field} );
        $table->Set_Row( [ $field, $value ] );
    }

    return $table->Printout(0);
}

#***********************
#************************
############################################
#
# Display Submission information
#
# Input:
# -trace_data: hash of database field data from get_Trace_data/Table_retrieve
#
# Example: { 'Trace_Submission_ID' => [1,2,3], 'FK_Run__ID' => [120100,120210,143000], ... }
#
# -fields: arrayref of fields available in "trace_data" to display in the table
# The order of fields in this argument also determines the order displayedin the table
#
# Example: ["Trace_Submission_ID", "Trace_Submission.FK_Run__ID", "Status_Name"]
#
############################################
sub Submission_Volume_display_hash {
############################################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $Volume_data  = $args{-volume_data};
    my $input_fields = $args{-fields};
    my $dbc          = $self->{dbc};
    my @keys;
    my %labels;
    my %fields;

    ### CONSTRUCTION:
    # display_hash is picky about how field names are entered, need this
    # code to get it in the right format

    # Parameters needed to display table correctly
    # keys: Determine order of column headers
    # labels: Text display as column header
    # fields: Used to automatically de-reference foreign key fields and
    # create an HTML link

    foreach my $field ( @{$input_fields} ) {

        my ( $t, $f ) = simple_resolve_field( -field => $field );

        $fields{$f} = $field;
        push @keys, $f;
        $labels{$f} = $f;

    }

    ### END CONSTRUCTION

    return SDB::HTML::display_hash( -hash => $Volume_data, -keys => \@keys, -labels => \%labels, -fields => \%fields, -selectable_field => "Submission_Volume_ID", -return_html => 1 );

}

sub new_SV_form {
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $Form_name = $args{-Form_name};

    my $output;
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Submission_Volume', -force => 1 );

    my ( $SV_input_table, $form_params ) = $self->_new_SV_form_table( -dbc => $dbc );
    $output .= $SV_input_table;

    $output .= RGTools::Web_Form::Submit_Button(
        -dbc  => $dbc,
        form  => "$Form_name",
        name  => "rm",
        value => "Confirm Submission Volume"
    );

    my $frozen = Safe_Freeze( -name => "Form_Params", -value => $form_params, -format => 'hidden', -encode => 1 );
    $output .= $frozen;

    $output .= end_form();
    return $output;

}

###
### The table with Submission_Volume input form elements is separated out from the actual form
### so that it can be used in inherited classes (like SRA::Data_Submission_Views)
### without having nested forms
###

sub _new_SV_form_table {
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    #my $target_orgs = $args{-target_orgs} || [];
    #my $templates   = $args{-templates} || [];

    my @form_params;

    my $SV_input_table = HTML_Table->init_table(
        -title  => "New Submission Volume",
        -width  => 400,
        -toggle => 'on'
    );
    $SV_input_table->Set_Border(1);

    ###
    ### Volume_Name
    ###

    my $form_param = "Volume_Name";
    my $name_field = b("Submission Volume Name:") 
        . br()
        . Show_Tool_Tip(
        textfield(
            -name    => $form_param,
            -size    => 40,
            -default => '',
            -force   => 1
        ),
        "Please give a name for the submission volume"
        );

    $SV_input_table->Set_Row( [$name_field] );
    push @form_params, $form_param;
    ###
    ### Requester_Employee__ID
    ###

    $form_param = "Requester_Employee";
    my @employee_array = $dbc->Table_find(
        -table     => 'Employee',
        -fields    => 'Employee_Name',
        -condition => "WHERE Employee_Status = 'Active'",
    );

    my $requester_field = b("Requester:") 
        . br()
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -mode    => 'scroll',
        -name    => $form_param,
        -scroll  => 4,
        -options => \@employee_array,
        -search  => 1,
        -filter  => 1,
        -sort    => 1,
        -tip     => 'Select the employee who requested the data submission',
        );

    $SV_input_table->Set_Row( [$requester_field] );
    push @form_params, $form_param;

    ###
    ### Target data archive
    ###

    $form_param = "Data_Archive";
    my @data_archives = $dbc->Table_find(
        -table     => 'Organization',
        -fields    => 'Organization_Name',
        -condition => "WHERE Organization_Type = 'Data Repository'",
        -distinct  => 1,
    );
    my $data_archive_field = b("Data Archive:") 
        . br()
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -mode    => 'scroll',
        -name    => $form_param,
        -scroll  => 4,
        -options => \@data_archives,
        -search  => 1,
        -filter  => 1,
        -sort    => 1,
        -tip     => 'Select target data archive to which the data will be submitted'
        );

    $SV_input_table->Set_Row( [$data_archive_field] );
    push @form_params, $form_param;

    ###
    ### Submission_Template
    ###

    $form_param = "Submission_Template";

    my @template_array = $dbc->Table_find(
        -table  => 'Submission_Template',
        -fields => 'Template_Name',
    );

    my $template_field = b("Template:") 
        . br()
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -mode    => 'scroll',
        -name    => $form_param,
        -scroll  => 4,
        -options => \@template_array,
        -search  => 1,
        -filter  => 1,
        -tip     => 'Select submission template to use'
        );

    $SV_input_table->Set_Row( [$template_field] );
    push @form_params, $form_param;

    ###
    ### Submission_Comments
    ###

    $form_param = "Submission_Comments";
    my $comments_field = b("Submission Comments:") 
        . br()
        . Show_Tool_Tip(
        textfield(
            -name    => $form_param,
            -size    => 40,
            -default => '',
            -force   => 1
        ),
        "Comments for the submission"
        );

    $SV_input_table->Set_Row( [$comments_field] );
    push @form_params, $form_param;

    ###
    ### For Trace_Submission entries:
    ###

    $form_param = "Library";
    my $library_field = b("Libraries: ") . br() . SDB::HTML::dynamic_text_element( -name => $form_param, -rows => 1, -cols => 10, -default => "", -force => 1, -max_rows => 10, -max_cols => 50, -split_commas => 1 );
    $SV_input_table->Set_Row( [$library_field] );
    push @form_params, $form_param;

    ###
    ###
    ###

    $form_param = "Run_ID";

    my $run_id_field = b("Run IDs: ") 
        . br()
        . Show_Tool_Tip(
        textfield(
            -name    => $form_param,
            -size    => 40,
            -default => '',
            -force   => 1
        ),
        "Comma separated list of run IDs or run IDs in range"
        );

    $run_id_field .= br() . "Example: '64653,74423' or '64653-64666'";

    $SV_input_table->Set_Row( [$run_id_field] );
    push @form_params, $form_param;

    $SV_input_table->Set_VAlignment('top');
    my $output .= $SV_input_table->Printout(0);

    if (wantarray) {
        return ( $output, \@form_params );
    }
    else {
        return $output;
    }

}

############################################
#
# Search page for data submission
#
############################################
sub display_search_page {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $data_submission_obj = new alDente::Submission_Volume( -dbc => $dbc );

    my $output;
    $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Submission_Volume_Search" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Submission_Volume_App' );

    ### search options table

    # init date search
    my $date_spec = "";
    $date_spec = &display_date_field(
        -field_name => "date_range",
        -default    => '',
        -quick_link => [ 'Today', '7 days', '1 month' ],
        -range      => 1,
        -linefeed   => 1,
        -force      => 1
    );

    # init target organization search
    my @target_org_array = @{ $data_submission_obj->get_target_organization_list() };
    unshift( @target_org_array, '-' );
    my $target_org_spec = '<B>Target Organization:</B><BR>'
        . popup_menu(
        -name   => 'Target Organization',
        -values => \@target_org_array,
        -force  => 1
        );

    # init data submission volume name search
    #my $submission_volume_name_spec = '<B>Submission Volume name:</B><BR>' . textfield( -name => 'Submission Volume name', -size => 20 );
    my $submission_volume_name_spec = "<B> Submission Volume Name: </B>" 
        . lbr()
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -name    => 'Submission_Volume.Volume_Name',
        -default => '',
        -search  => 1,
        -filter  => 1,
        -breaks  => 1,
        -width   => 390,
        -mode    => 'Scroll',
        -force   => 1,
        );

    # init employee search
    my @emp_array = $dbc->Table_find( "Employee,Submission_Volume", "distinct Employee_Name", "WHERE FKRequester_Employee__ID = Employee_ID" );
    unshift( @emp_array, '-' );
    my $employee_spec = '<B>Requester:</B><BR>' . popup_menu( -name => 'Employee', -values => \@emp_array, -force => 1 );

    # init submission volume status search
    my @volume_status_array = @{ $data_submission_obj->get_volume_status_list() };
    unshift( @volume_status_array, '-' );
    my $volume_status_spec = '<B>Submission Volume Status:</B><BR>'
        . popup_menu(
        -name   => 'Submission Volume Status',
        -values => \@volume_status_array,
        -force  => 1
        );

    # init run data submission status search
    my @run_status_array = @{ $data_submission_obj->get_run_data_status_list() };
    unshift( @run_status_array, '-' );
    my $run_status_spec = '<B>Run Data Status:</B><BR>'
        . popup_menu(
        -name   => 'Run Data Submission Status',
        -values => \@run_status_array,
        -force  => 1
        );

    # init submission volume id search
    #my $request_spec = '<B>Request IDs:</B><BR>' . textfield( -name => 'Submission Volume Request IDs', -size => 20, -force => 1 );

    # init library search
    # get all libraries that have runs/traces submitted
    my @lib_options = $dbc->Table_find(
        -table     => 'Trace_Submission,Run,Plate',
        -fields    => 'FK_Library__Name',
        -condition => "WHERE FK_Run__ID = Run_ID and FK_Plate__ID = Plate_ID",
        -distinct  => 1,
    );
    my $library_spec = "<B> Library: </B>" 
        . lbr()
        . alDente::Tools::search_list(
        -dbc            => $dbc,
        -name           => 'Library.Library_Name',
        -default        => '',
        -search         => 1,
        -filter         => 1,
        -options        => \@lib_options,
        -sort           => 1,
        -breaks         => 1,
        -width          => 390,
        -filter_by_dept => 1,
        -mode           => 'Scroll',
        -force          => 1,
        -tip            => "Enter library (or portion of library name to filter);",
        );

    # init project search
    # get all projects that have runs/traces submitted
    my @project_options = $dbc->Table_find(
        -table     => 'Trace_Submission,Run,Plate,Library,Project',
        -fields    => 'Project_Name',
        -condition => "WHERE FK_Run__ID = Run_ID and FK_Plate__ID = Plate_ID and FK_Library__Name = Library_Name and FK_Project__ID = Project_ID",
        -distinct  => 1,
    );
    my $project_spec = "<B> Project: </B>" 
        . lbr()
        . alDente::Tools::search_list(
        -dbc            => $dbc,
        -name           => 'Project.Project_Name',
        -default        => '',
        -search         => 1,
        -filter         => 1,
        -options        => \@project_options,
        -sort           => 1,
        -breaks         => 1,
        -width          => 390,
        -filter_by_dept => 1,
        -mode           => 'Scroll',
        -force          => 1,
        -tip            => "Enter project name(or portion of project name to filter);",
        );

    # Submission_Type is a deprecated field
    #
    #my @submission_type_array = @{ $data_submission_obj->get_valid_submission_types() };
    #unshift( @submission_type_array, '-' );
    #my $submission_type_spec = '<B>Submission Type:</B><BR>' . popup_menu( -name => 'Submission_Type', -values => \@submission_type_array, -force => 1 );

    my $data_submission_search = HTML_Table->init_table(
        -title  => "Submission Volume Search",
        -width  => 900,
        -toggle => 'on'
    );
    $data_submission_search->Set_Border(1);
    $data_submission_search->Set_Row( [ $date_spec, $library_spec, $target_org_spec, $employee_spec ] );
    $data_submission_search->Set_Row( [ $submission_volume_name_spec, $project_spec, $volume_status_spec, $run_status_spec ] );
    $data_submission_search->Set_Row(
        [   RGTools::Web_Form::Submit_Button(
                -dbc  => $dbc,
                form  => "Submission_Volume_Search",
                name  => "rm",
                value => "View Submission Volumes"
            )
        ]
    );
    $data_submission_search->Set_VAlignment('top');
    $output .= $data_submission_search->Printout(0);
    $output .= "<BR>";

    $output .= end_form();
    return $output;
}

########################################
# View for incomplete submission volumes
#
# Return:	html page
########################################
sub display_incomplete_Submission_Volume {
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my @incomplete_statuses = ( 'Requested', 'Created', 'Bundled', 'Submitted', 'In Process', 'Waiting for Admin', 'Approved by Admin' );
    my $incomplete_status_str = Cast_List( -to => 'string', -list => \@incomplete_statuses, -autoquote => 1 );

    my $output;
    my @fields = (
        'Submission_Volume_ID as Submission_Volume',
        'FK_Organization__ID AS Target_Organization',
        'FK_Submission_Template__ID AS Template',
        'FKRequester_Employee__ID AS Requester',
        'Volume_Status.Status_Name as Volume_Status',
        'GROUP_CONCAT(distinct Trace_Status.Status_Name) AS Run_Status',
        'COUNT(*) AS Num_Runs',
        'Volume_Comments AS Comments',
    );

    my $condition = "WHERE 1";
    my $table     = 'Submission_Volume,Trace_Submission,Status as Volume_Status,Status as Trace_Status';

    my $join_condition
        = " and FK_Submission_Volume__ID = Submission_Volume_ID and Volume_Status.Status_Type = 'Submission' and Trace_Status.Status_Type = 'Submission' and Volume_Status.Status_ID = Submission_Volume.FK_Status__ID and Trace_Status.Status_ID = Trace_Submission.FK_Status__ID";

    my $filter_condition = " and Volume_Status.Status_Name in ($incomplete_status_str) and Trace_Status.Status_Name in ($incomplete_status_str)";

    $condition .= $join_condition . $filter_condition;
    my %Results = $dbc->Table_retrieve(
        -table     => $table,
        -fields    => \@fields,
        -condition => $condition,
        -group     => 'Submission_Volume_ID',
        -order     => 'Submission_Date desc'
    );

    ### %display_hash_fields is a hash like ( <SQL alias> => <SQL field> )'
    ### Necessary for display_hash so that any FK fields get dereferenced
    ### to the object value, not just the FK numerical value
    my %display_hash_fields;

    ### Array of SQL aliases to set order of columns in table
    my @headers;

    foreach my $field (@fields) {
        my $alias;
        if ( $field =~ /(.+) AS (.+)/i ) {
            $field = $1;
            $alias = $2;
        }
        else {
            $alias = $field;
        }

        $display_hash_fields{$alias} = $field;
        push @headers, $alias;
    }

    ##### Using display_hash instead of Table_retrieve

    $output = SDB::HTML::display_hash( -hash => \%Results, -keys => \@headers, -fields => \%display_hash_fields, -return_html => 1 );

    return $output;
}

=begin
############################################
#
# new data submission - DEPRECATED 2010-11-12
#
############################################
sub new_submission_volume_page {
###########################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my @lib_options = @{ $args{-library_options} };
    my @custom_spec = @{ $args{-custom_specifications} };

    my $data_submission_obj = new alDente::Submission_Volume( -dbc => $dbc );
    my $output;
    $output = alDente::Form::start_alDente_form(-dbc=>$dbc, -name=>"Data_Submission_Request");
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Submission_Volume_App' );

    ## volume name
    my $name_spec = Show_Tool_Tip( '<B>Submission Name: </B>', "Please give a name for the submission" ) . Show_Tool_Tip( textfield( -name => 'Request_Name', -size => 40, -default => '', -force => 1 ), "Please give a name for the submission" );

    ## requester
    my @employee_array = $dbc->Table_find(
        -table     => 'Employee',
        -fields    => 'Employee_Name',
        -condition => "WHERE Employee_Status = 'Active'",
    );
    my $requester_spec = '<B>Requester:</B><BR>'
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -mode    => 'scroll',
        -name    => 'Requester',
        -scroll  => 4,
        -options => \@employee_array,
        -search  => 1,
        -filter  => 1,
        -sort    => 1,
        -tip     => 'Select the employee who requested the data submission',
        );

    ## target organization
    my @target_org_array = @{ $data_submission_obj->get_valid_target_organizations( -dbc => $dbc ) };
    my $target_org_spec = '<B>Target Organization:</B><BR>'
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -mode    => 'scroll',
        -name    => 'Target_Organization',
        -scroll  => 4,
        -options => \@target_org_array,
        -search  => 1,
        -filter  => 1,
        -sort    => 1,
        -tip     => 'Select target organization to which the data will be submitted'
        );

    ## study ID for STUDY meta data of the submission
    my $study_study_spec = Show_Tool_Tip( '<B>STUDY Study ID: </B>', "Please specify the study ID for the STUDY meta data of the submission" )
        . Show_Tool_Tip( textfield( -name => 'Study_Study_ID', -size => 40, -default => '', -force => 1 ), "Please specify the study ID for the STUDY meta data of the submission" );

    ## study ID for the sample being studied
    my $study_sample_spec = Show_Tool_Tip( '<B>SAMPLE Study ID: </B>', "Please specify the study ID for the sample being studied" )
        . Show_Tool_Tip( textfield( -name => 'Sample_Study_ID', -size => 40, -default => '', -force => 1 ), "Please specify the study ID for the sample being studied" );

    my $comments_spec = Show_Tool_Tip( '<B>Submission Comments: </B>', "Comments for the submission" ) . Show_Tool_Tip( textfield( -name => 'Submission_Comments', -size => 40, -default => '', -force => 1 ), "Comments for the submission" );

    #my $library_spec = '<B>Library:</B><BR>'
    #    . alDente::Tools::search_list(
    #    -dbc     => $dbc,
    #    -mode    => 'scroll',
    #    -name    => 'Library.Library_Name',
    #    -search  => 1,
    #    -filter  => 1,
    #    -options => \@lib_options,
    #    -size    => 8,
    #    -breaks  => 1,
    #    -sort    => 1,
    #    -tip     => "Enter library (or portion of library name to filter);"
    #    );
    my $library_spec = Show_Tool_Tip( '<B>Libraries: </B><BR>', "Comma separated list of library names" ) . Show_Tool_Tip( textfield( -name => 'Library', -size => 40, -default => '', -force => 1 ), "Comma separated list of library names" );

    my $run_id_spec
        = Show_Tool_Tip( '<B>Run IDs: </B><BR>', "Comma separated list of run IDs or run IDs in range" )
        . Show_Tool_Tip( textfield( -name => 'Run_ID', -size => 40, -default => '', -force => 1 ), "Comma separated list of run IDs or run IDs in range" )
        . "<BR>eg: '64653,74423' or '64653-64666'";
    my @valid_run_file_types = ( 'SRF', 'fastq' );
    my $run_file_type_spec = '<B>Run File Type:</B><BR>'
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -mode    => 'scroll',
        -name    => 'Run_File_Type',
        -scroll  => 2,
        -options => \@valid_run_file_types,
        -search  => 1,
        -filter  => 1,
        -tip     => 'Select the run data file type that you want to submit'
        );

    my $submission_type_spec .= hidden( -name => 'Submission_Type', -value => 'SRA', -force => 1 );

    my $request = HTML_Table->init_table(
        -title  => "New Data Submission",
        -width  => 400,
        -toggle => 'on'
    );
    $request->Set_Border(1);
    $request->Set_Row( [$name_spec] );
    $request->Set_Row( [$requester_spec] );
    $request->Set_Row( [$target_org_spec] );
    $request->Set_Row( [$run_file_type_spec] );
    $request->Set_Row( [$study_study_spec] );
    $request->Set_Row( [$study_sample_spec] );
    $request->Set_Row( [$library_spec] );
    $request->Set_Row( [$run_id_spec] );
    $request->Set_Row( [$submission_type_spec] );

    if (@custom_spec) {
        foreach my $spec (@custom_spec) {
            $request->Set_Row( [$spec] );
        }
    }

    $request->Set_Row( [$comments_spec] );
    $request->Set_Row(
        [   RGTools::Web_Form::Submit_Button(
                -dbc  => $dbc,
                form  => "Data_Submission_Request",
                name  => "rm",
                value => "Request Data Submission"
            )
        ]
    );
    $request->Set_VAlignment('top');
    $output .= $request->Printout(0);
    $output .= "<BR>";
    $output .= end_form();
    return $output;
}
=cut

sub param_summary_table {
    my $self           = shift;
    my %args           = filter_input( \@_, -args => 'request_params', -mandatory => 'request_params' );
    my $dbc            = $args{-dbc} || $self->{'dbc'};
    my $request_params = $args{-request_params};

    my @params = ();
    my @values = ();

    push @params, "Submission Name";
    push @values, $request_params->{name};

    if ( $request_params->{requester} ) {
        push @params, "Requester";
        push @values, $request_params->{requester};
    }
    if ( $request_params->{target} ) {
        push @params, "Target Organization";
        push @values, $request_params->{target};
    }
    if ( $request_params->{run_file_type} ) {
        push @params, "Run File Type";
        push @values, $request_params->{run_file_type};
    }
    if ( $request_params->{library} ) {
        push @params, "Libraries";
        push @values, $request_params->{library};
    }
    if ( $request_params->{run_id} ) {
        push @params, "Run IDs";
        push @values, $request_params->{run_id};
    }
    ######################
    if ( $request_params->{template} ) {
        push @params, "Submission Template";
        push @values, $request_params->{template};
    }
    #########
    if ( $request_params->{comments} ) {
        push @params, "Submission Comments";
        push @values, $request_params->{comments};
    }
    if ( $request_params->{selected_runs} ) {

        my @runs;
        my @sample_ids;

        foreach my $run_sample ( @{ $request_params->{selected_runs} } ) {

            my ( $run, $sample_id ) = split /-/, $run_sample;

            push @runs,       $run;
            push @sample_ids, $sample_id;
        }

        my $sample_id_string = Cast_List( -to => 'string', -list => \@sample_ids );

        my @output = $dbc->Table_find( -table => "Sample", -fields => "Sample_ID,Sample_Name", -condition => "where Sample_ID in ($sample_id_string)" );

        my %id_to_name = map { split /,/, $_ } @output;

        my $run_list;
        foreach my $i ( 0 .. $#runs ) {
            $run_list .= "Run: $runs[$i]\tSample: $id_to_name{$sample_ids[$i]}\n";
        }

        push @params, "Selected runs";
        push @values, $run_list;
    }

    if ( $request_params->{selected_run_analysis} ) {

        my $analysis_list;

        foreach my $pair ( @{ $request_params->{selected_run_analysis} } ) {

            my ( $run_analysis, $multiplex_run_analysis ) = split /-/, $pair;

            $analysis_list .= "Run Analysis: $run_analysis";
            if ($multiplex_run_analysis) {
                $analysis_list .= "\tMultiplex Run Analysis: $multiplex_run_analysis\n";
            }
            else {
                $analysis_list .= "\n";
            }
        }

        push @params, "Selected run analyses";
        push @values, $analysis_list;
    }

    my %content = ( '1' => \@params, '2' => \@values );

    my %labels = ( '1' => 'Parameters', '2' => 'Input Values' );
    my $output = SDB::HTML::display_hash(
        -dbc         => $dbc,
        -title       => "Submission Volume attributes",
        -hash        => \%content,
        -labels      => \%labels,
        -border      => 1,
        -return_html => 1,
    );

    return $output;

}

sub view_data_submissions {
    my $self = shift;

    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc};
    my $debug = $args{-debug};

    my $from_date           = $args{-from_date};
    my $to_date             = $args{-to_date};
    my $target_organization = $args{-target_organization};
    my @volume_names        = @{ $args{-volume_name} };
    my $emp_id              = $args{-emp_id};
    my $volume_status       = $args{-volume_status};
    my $run_data_status     = $args{-run_data_status};
    my @libraries           = @{ $args{-libraries} };
    my @projects            = @{ $args{-projects} };
    my $submission_type     = $args{-submission_type};

    my $extra_condition;

    if ($from_date) {
        $extra_condition .= " AND Submission_Date >= '$from_date 00:00:00' ";
    }

    if ($to_date) {
        $extra_condition .= " AND Submission_Date <= '$to_date 23:59:59' ";
    }

    if ($target_organization) {
        $extra_condition .= " AND Organization_Name = '$target_organization' ";
    }

    if (@volume_names) {
        my $vol_str = Cast_List( -list => \@volume_names, -to => 'string', -autoquote => 1 );
        if ( $vol_str && $vol_str ne qq('') ) { $extra_condition .= " AND Volume_Name in ($vol_str) " }
    }

    if (@libraries) {
        my $lib_str = Cast_List( -list => \@libraries, -to => 'string', -autoquote => 1 );
        if ( $lib_str && $lib_str ne qq('') ) { $extra_condition .= " AND FK_Library__Name in ($lib_str) " }
    }

    if (@projects) {
        my $projects_str = Cast_List( -list => \@projects, -to => 'string', -autoquote => 1 );
        if ( $projects_str && $projects_str ne qq('') ) { $extra_condition .= " AND Project_Name in ($projects_str) " }
    }

    if ($emp_id) {
        $extra_condition .= " AND Submission_Volume.FKRequester_Employee__ID in ($emp_id) ";
    }

    if ($volume_status) {
        $extra_condition .= " AND Status_Name = '$volume_status' ";
    }

    if ($run_data_status) {
        $extra_condition .= " AND Submission_Status = '$run_data_status' ";
    }

    if ($submission_type) {
        $extra_condition .= " AND Submission_Type = '$submission_type' ";
    }

    my @field_list = (
        "Submission_Volume_ID as Submission_Volume",
        "Submission_Type",
        "Organization_Name as Target_Organization",
        "Group_CONCAT(distinct Concat(FK_Library__Name) separator ' ') as Libraries",
        "Template_Name as Template",
        "Status_Name as Volume_Status",
        "Group_CONCAT( distinct Submission_Status ) as Run_Data_Status",
        "COUNT(*) AS Number_Runs",
        "Submission_Date as Request_Date",
        "Employee_Name as Requester",
        "Volume_Comments as Comment",
    );

    my $tables = "Submission_Volume,Trace_Submission,Run,Plate,Library,Project,Employee,Organization,Status ";
    $tables .= " LEFT JOIN Submission_Template ON FK_Submission_Template__ID = Submission_Template_ID";

    my $condition
        = "WHERE FK_Submission_Volume__ID = Submission_Volume_ID and Trace_Submission.FK_Run__ID = Run.Run_ID and Submission_Volume.FK_Organization__ID = Organization_ID and Status_ID = Submission_Volume.FK_Status__ID and Status_Type = 'Submission'";
    $condition .= " and Run.FK_Plate__ID = Plate.Plate_ID and FK_Library__Name = Library_Name";
    $condition .= " and FK_Project__ID = Project_ID and Submission_Volume.FKRequester_Employee__ID=Employee_ID ";
    $condition .= " $extra_condition" . " group by Submission_Volume_ID order by Submission_Volume_ID";
    print "Condition: $condition\n\n" if ($debug);
    return $dbc->Table_retrieve_display(
        -title       => 'Submission Volume',
        -return_html => 1,
        -table       => $tables,
        -fields      => \@field_list,
        -condition   => $condition,
        -debug       => $debug,
    );
}

############################################
#
# Display data submission summary page
#
# Return:	html page
############################################
sub data_submission_summary_page {
###########################
    my $self            = shift;
    my %args            = filter_input( \@_, -args => 'dbc,project_options,-custom_specifications,scope', -mandatory => 'project_options,scope' );
    my $dbc             = $args{-dbc} || $self->{dbc};
    my @project_options = @{ $args{-project_options} };
    my @custom_spec     = @{ $args{-custom_specifications} };
    my $scope           = $args{-scope};

    my $data_submission_obj = new alDente::Submission_Volume( -dbc => $dbc );

    my $output;
    $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Data_Submission_Summary" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Submission_Volume_App' );
    $output .= hidden( -name => 'Scope',           -value => $scope );

    ### summary options

    # init date search
    my $date_spec = "";
    $date_spec = &display_date_field(
        -field_name => "date_range",
        -default    => '',
        -quick_link => [ 'Today', '7 days', '1 month' ],
        -range      => 1,
        -linefeed   => 1,
        -force      => 1
    );

    ## target organization
    my @target_org_array = @{ $data_submission_obj->get_valid_target_organizations( -dbc => $dbc ) };
    my $target_org_spec = '<B>Target Organization:</B><BR>'
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -mode    => 'scroll',
        -name    => 'Target_Organization',
        -scroll  => 2,
        -options => \@target_org_array,
        -search  => 1,
        -filter  => 1,
        -tip     => 'Select target organization to which the data was submitted'
        );

    ## project spec
    my $project_spec = "<B> Project: </B><BR>"
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -mode    => 'scroll',
        -name    => 'Project.Project_Name',
        -search  => 1,
        -filter  => 1,
        -options => \@project_options,
        -size    => 8,
        -breaks  => 1,
        -sort    => 1,
        -force   => 1,
        -tip     => "Enter project name(or portion of project name to filter);",
        );

    my $summary = HTML_Table->init_table(
        -title  => "$scope Data Submission Summary",
        -width  => 400,
        -toggle => 'on'
    );
    $summary->Set_Border(1);
    $summary->Set_Row( [$date_spec] );
    $summary->Set_Row( [$target_org_spec] );
    $summary->Set_Row( [$project_spec] );

    if (@custom_spec) {
        foreach my $spec (@custom_spec) {
            $summary->Set_Row( [$spec] );
        }
    }

    $summary->Set_Row(
        [   RGTools::Web_Form::Submit_Button(
                -dbc  => $dbc,
                form  => "Data_Submission_Summary",
                name  => "rm",
                value => "Generate Summary"
            )
        ]
    );
    $summary->Set_VAlignment('top');
    $output .= $summary->Printout(0);
    $output .= "<BR>";
    $output .= end_form();
    return $output;

}

=begin
############################################
#
# Display action buttons for a specific Submission Volume
#
############################################
sub display_meta_action_button {
############################################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $volume_info = $args{-volume_info};
    my $form_name   = $args{-form_name};

    my $admin = grep /\bAdmin$/, @{ $dbc->get_local('groups') };

    my $table = HTML_Table->new( -width => 300, -border => 0 );
    $table->Toggle_Colour('off');
    $table->Set_Padding(0);
    $table->Set_Line_Colour("#FFFFFF");

    if ($admin) {
        my $submission_views = $self->get_submission_views( -scope => $volume_info->{Submission_Type} );
        if ( !$submission_views ) {
            Message("WARNING: No appropriate Submission_Views object for submission type $volume_info->{Submission_Type}!");
            return;
        }
        my $custom_spec = $submission_views->display_meta_action_button(
            -dbc         => $dbc,
            -volume_info => $volume_info,
            -form_name   => $form_name
        );
        $table->Set_Row( [$custom_spec] ) if ($custom_spec);

        my @actions;
        ## if the Volume_Status is "Requested", display button for creating meta data
        if ( $volume_info->{Volume_Status} eq 'Requested' ) {
            push @actions, "Create Meta Data";
        }
        ## if the Volume_Status is "Created", display button to pass validation
        if ( $volume_info->{Volume_Status} eq 'Created' ) {
            push @actions, ( "Re-Create Meta Data", "Pass Validation" );
        }
        ## if the Volume_Status is "Validated", display button to bundle meta data
        if ( $volume_info->{Volume_Status} eq 'Validated' ) {
            push @actions, "Bundle Meta Data";
        }
        ## if the Volume_Status is "Bundled", display button to upload meta data
        if ( $volume_info->{Volume_Status} eq 'Bundled' ) {
            push @actions, "Upload Meta Data";
        }
        ## if the Volume_Status is "Submitted", display button to update the status to "Accepted" / "Rejected", enable entry of accession
        if ( $volume_info->{Volume_Status} eq 'Submitted' ) {
            push @actions, "Set_Accession" if ( !$volume_info->{Accession} );
            push @actions, ( "Meta Data Accepted", "Meta Data Rejected" );
        }
        ## if the Volume_Status is "Accepted", display button to release the data, enable entry of accession
        if ( $volume_info->{Volume_Status} eq 'Accepted' ) {
            push @actions, "Set_Accession" if ( !$volume_info->{Accession} );
            push @actions, "Release Data";
        }
        ## if the Volume_Status is "Rejected", display button to accept the data, enable entry of accession
        if ( $volume_info->{Volume_Status} eq 'Rejected' ) {
            push @actions, "Set_Accession" if ( !$volume_info->{Accession} );
            push @actions, "Meta Data Accepted";
        }
        ## if the Volume_Status is "Released", enable entry of accession
        if ( $volume_info->{Volume_Status} eq 'Released' ) {
            push @actions, "Set_Accession" if ( !$volume_info->{Accession} );
        }

        foreach my $action (@actions) {
            if ( $action eq 'Set_Accession' ) {
                $self->display_set_accession(
                    -dbc       => $dbc,
                    -table     => $table,
                    -form_name => $form_name
                );
            }
            else {
                $table->Set_Row(
                    [   RGTools::Web_Form::Submit_Button(
                            -dbc  => $dbc,
                            form  => $form_name,
                            name  => "rm",
                            value => $action
                        )
                    ]
                );
            }
        }

        $table->Set_Row( ['<BR>'] );
        my $input_comments = textfield( -name => 'Comments', -size => 20, -force => 1 );
        $table->Set_Row(
            [   $input_comments,
                RGTools::Web_Form::Submit_Button(
                    -dbc  => $dbc,
                    form  => $form_name,
                    name  => "rm",
                    value => "Update Comments"
                ),
            ]
        );
    }
    my $return = $table->Printout(0) . "<BR>";
    return $return;
}
=cut

##############################
# Display input box to set accession #
#
# Return:	html page
###############################
sub display_set_accession {
############################
    my $self = shift;
    my %args = filter_input(
         \@_,
        -args      => 'dbc,table,form_name',
        -mandatory => 'dbc,table,form_name'
    );
    my $dbc       = $args{-dbc};
    my $table     = $args{-table};
    my $form_name = $args{-form_name};

    $table->Set_Row( ['<BR>'] );
    my $input_accession = '<B>Accession#: </B>' . textfield( -name => 'Accession', -size => 20, -force => 1 );
    $table->Set_Row(
        [   $input_accession,
            RGTools::Web_Form::Submit_Button(
                -dbc  => $dbc,
                form  => $form_name,
                name  => "rm",
                value => "Set Accession"
            )
        ]
    );
    return $input_accession;
}

############################################
#
# Display the page to get study information
#
############################################
sub get_study_page {
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

}

###########################################################
# Get the custom submission views object specified by -scope
#
# Usage:	my $submission_views_obj = get_submission_views( -scope => 'SRA' );
#			my $submission_views_obj = get_submission_views( -scope => 'TRACE' );
#
# Return:	submission views object reference
###########################
sub get_submission_views {
###########################
    my $self  = shift;
    my %args  = &filter_input( \@_, -args => 'dbc,scope', -mandatory => 'scope' );
    my $dbc   = $args{-dbc} || $self->param('dbc');
    my $scope = $args{-scope};

    if ( $scope eq 'SRA' ) {
        require SRA::Data_Submission_Views;
        return new SRA::Data_Submission_Views( -dbc => $dbc );
    }
    elsif ( $scope eq 'TRACE' ) {
        require Trace_Archive::Trace_Archive_Views;
        return new Trace_Archive::Trace_Archive_Views( -dbc => $dbc );
    }
}

############################################
#
# Summary page for SRA data submission
#
############################################
sub display_summary_page {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $data_submission_obj = new alDente::Submission_Volume( -dbc => $dbc );

    my $output;
    $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Submission_Volume_Search" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Submission_Volume_App' );

    ### search options table

    # init date search
    my $date_spec = "";

    $date_spec = &display_date_field(
        -field_name => "date_range",
        -default    => '',
        -quick_link => [ 'Today', '7 days', '1 month' ],
        -range      => 1,
        -linefeed   => 1,
        -force      => 1
    );

    # init target organization search
    my @target_org_array = @{ $data_submission_obj->get_target_organization_list() };
    unshift( @target_org_array, '-' );
    my $target_org_spec = '<B>Target Organization:</B><BR>'
        . popup_menu(
        -name   => 'Target Organization',
        -values => \@target_org_array,
        -force  => 1
        );

    # init data submission volume name search
    #my $submission_volume_name_spec = '<B>Submission Volume name:</B><BR>' . textfield( -name => 'Submission Volume name', -size => 20 );
    my $submission_volume_name_spec = "<B> Submission Volume Name: </B>" 
        . lbr()
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -name    => 'Submission_Volume.Volume_Name',
        -default => '',
        -search  => 1,
        -filter  => 1,
        -breaks  => 1,
        -width   => 390,
        -mode    => 'Scroll',
        -force   => 1,
        );

    # init employee search
    my @emp_array = $dbc->Table_find( "Employee,Submission_Volume", "distinct Employee_Name", "WHERE FKRequester_Employee__ID = Employee_ID" );
    unshift( @emp_array, '-' );
    my $employee_spec = '<B>Requester:</B><BR>' . popup_menu( -name => 'Employee', -values => \@emp_array, -force => 1 );

    # init submission volume status search
    my @volume_status_array = @{ $data_submission_obj->get_volume_status_list() };
    unshift( @volume_status_array, '-' );
    my $volume_status_spec = '<B>Submission Volume Status:</B><BR>'
        . popup_menu(
        -name   => 'Submission Volume Status',
        -values => \@volume_status_array,
        -force  => 1
        );

    # init run data submission status search
    my @run_status_array = @{ $data_submission_obj->get_run_data_status_list() };
    unshift( @run_status_array, '-' );
    my $run_status_spec = '<B>Run Data Status:</B><BR>'
        . popup_menu(
        -name   => 'Run Data Submission Status',
        -values => \@run_status_array,
        -force  => 1
        );

    # init submission volume id search
    #my $request_spec = '<B>Request IDs:</B><BR>' . textfield( -name => 'Submission Volume Request IDs', -size => 20, -force => 1 );

    # init library search
    # get all libraries that have runs/traces submitted
    my @options = $dbc->Table_find(
        -table     => 'Trace_Submission,Run,Plate',
        -fields    => 'FK_Library__Name',
        -condition => "WHERE FK_Run__ID = Run_ID and FK_Plate__ID = Plate_ID",
        -distinct  => 1,
    );
    my $library_spec = "<B> Library: </B>" 
        . lbr()
        . alDente::Tools::search_list(
        -dbc            => $dbc,
        -name           => 'Library.Library_Name',
        -default        => '',
        -search         => 1,
        -filter         => 1,
        -options        => \@options,
        -sort           => 1,
        -breaks         => 1,
        -width          => 390,
        -filter_by_dept => 1,
        -mode           => 'Scroll',
        -force          => 1,
        -tip            => "Enter library (or portion of library name to filter);",
        );

    my $data_submission_search = HTML_Table->init_table(
        -title  => "Submission Volume Search",
        -width  => 900,
        -toggle => 'on'
    );
    $data_submission_search->Set_Border(1);
    $data_submission_search->Set_Row( [ $date_spec, $library_spec, $target_org_spec, $employee_spec ] );
    $data_submission_search->Set_Row( [ $submission_volume_name_spec, $volume_status_spec, $run_status_spec, '' ] );
    $data_submission_search->Set_Row(
        [   RGTools::Web_Form::Submit_Button(
                -dbc  => $dbc,
                form  => "Submission_Volume_Search",
                name  => "rm",
                value => "View Submission Volumes"
            )
        ]
    );
    $data_submission_search->Set_VAlignment('top');
    $output .= $data_submission_search->Printout(0);
    $output .= "<BR>";

    $output .= end_form();
    return $output;
}

=begin
##############################################
#
# Display new data submission confirmation page
#
##############################################
sub display_confirm_data_submission_request_page {
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,request_params,run_info', -mandatory => 'request_params' );
    my $dbc  = $args{-dbc} || $self->{dbc};
	my $request_params = $args{-request_params};
	my $run_info = $args{-run_info}; # for displaying runs of this submission request
	
	my $run_ids = $request_params->{run_ids}; # for passing the run IDs to the App

    my $confirm = HTML_Table->init_table( -width  => 400 );
	$confirm->Set_Row(
		[	RGTools::Web_Form::Submit_Button(
                -dbc  => $dbc,
                form  => "Data_Submission_Request_Confirmation_Runs",
                name  => "rm",
                value => "Confirm Runs",
            ),
            RGTools::Web_Form::Submit_Button(
                -dbc  => $dbc,
                form  => "Data_Submission_Request_Confirmation_Runs",
                name  => "rm",
                value => "Cancel Data Submission Request",
            )
		]
	);
    $confirm->Set_VAlignment('top');
	
    my $output;
    $output = alDente::Form::start_alDente_form(-dbc=>$dbc, -name=>"Data_Submission_Request_Confirmation_Runs");
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Submission_Volume_App', -force => 1 );
    my $frozen = Safe_Freeze( -name => "Data_Submission_Request_Params", -value => $request_params, -format => 'hidden', -encode => 1 );
    $output .= $frozen;
    #if( $run_ids ) {
	#	$frozen = Safe_Freeze( -name => "Data_Submission_Request_Run_IDs", -value => $run_ids, -format => 'hidden', -encode => 1 );
    #	$output .= $frozen;
    #}

	$output .= $run_info . "<BR>" . $confirm->Printout(0);
    $output .= "<BR>";
    $output .= end_form();
	return $output;
}
=cut

##############################################
#
# Display new data submission custom confirmation page
#
##############################################
sub display_new_submission_volume_custom_confirm_page {
    my $self               = shift;
    my %args               = filter_input( \@_, -args => 'dbc,request_params,custom_label,custom_info,custom_hidden_info', -mandatory => 'request_params' );
    my $dbc                = $args{-dbc} || $self->{dbc};
    my $request_params     = $args{-request_params};
    my $custom_label       = $args{-custom_label};
    my $custom_info        = $args{-custom_info};
    my $custom_hidden_info = $args{-custom_hidden_info};

    #my $run_ids = $args{-run_ids}; # for passing the run IDs to the App

    my $confirm = HTML_Table->init_table( -width => 400 );
    $confirm->Set_Row(
        [   RGTools::Web_Form::Submit_Button(
                -dbc  => $dbc,
                form  => "New_Submission_Volume_Custom_Confirm",
                name  => "rm",
                value => "Confirm"
            )
        ]
    );

    my $output;
    $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "New_Submission_Volume_Custom_Confirm" );
    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Submission_Volume_App' );

    my $frozen;
    $frozen = Safe_Freeze( -name => "Data_Submission_Request_Params", -value => $request_params, -format => 'hidden', -encode => 1 );
    $output .= $frozen;

    #if( $run_ids ) {
    #	$frozen = Safe_Freeze( -name => "Data_Submission_Request_Run_IDs", -value => $run_ids, -format => 'hidden', -encode => 1 );
    #	$output .= $frozen;
    #}
    $output .= "<BR>";
    foreach my $key ( keys %$custom_hidden_info ) {
        $output .= hidden( -name => $key, -value => $custom_hidden_info->{$key} );
    }
    $output .= $custom_info . "<BR>" . $confirm->Printout(0);
    $output .= "<BR>";
    $output .= end_form();
    return $output;
}

return 1;

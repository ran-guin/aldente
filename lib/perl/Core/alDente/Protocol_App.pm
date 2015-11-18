############################
# alDente::Protocol_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Protocol_App;
use base alDente::CGI_App;

use strict;
##############################
# standard_modules_ref       #
##############################

############################
## Local modules required ##
############################

use RGTools::RGIO;
use RGTools::RGmath;

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use alDente::Protocol;
use alDente::Protocol_Views;
use SDB::Import;
use SDB::Import_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs);    #

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                      => 'home_page',
            'Home Page'                    => 'home_page',
            'Back to Home'                 => 'home_page',
            'Back to Protocol Admin Page'  => 'home_page',
            'Refresh Protocol List'        => 'home_page',
            'Save New Protocol'            => 'save_new_protocol',
            'Create New Protocol'          => 'create_protocol_prompt',
            'Delete Protocol'              => 'delete_Protocol',
            'Edit Protocol Visibility'     => 'edit_Protocol_Visibility',
            'Set Groups'                   => 'edit_Protocol_Visibility',
            'Edit Protocol Name'           => 'update_Protocol_Name',
            'Update Access'                => 'update_Protocol_Access',
            'Save As New Protocol'         => 'save_as_new_protocol_View',
            'Confirm Save As New Protocol' => 'save_as_new_protocol',
            'View Protocol'                => 'view_protocol',
            'View Step'                    => 'step_Actions',
            'Change Status'                => 'change_Protocol_Status',
            'Delete Step'                  => 'delete_step',
            'Save Step'                    => 'save_step_details',
            'Accept TechD Protocol'        => 'accept_protocol',

            #   'Update Protocol'           => 'update_protocol',
            #   'Add Step'                  => 'addstep',
            #   'Save Changes'              => 'save_step',
            #   'Next Step'                 => 'editstep',
            #   'Previous Step'             => 'editstep',
        }
    );

    my $dbc   = $self->param('dbc');
    my $q     = $self->query();
    my $id    = $q->param("Protocol_ID");
    my $admin = $q->param("Admin");
    if ( !$admin ) {    # check the user access in case no Admin param passed in
        my $access = $dbc->get_local('Access');
        if ( ( grep {/Admin/xmsi} @{ $access->{ $dbc->config('Target_Department') } } ) || $access->{'LIMS Admin'} ) {
            $admin = '1';
        }
    }
    my $Protocol = new alDente::Protocol( -dbc => $dbc, -id => $id );
    my $Protocol_View = new alDente::Protocol_Views( -dbc => $dbc, -model => { 'Protocol' => $Protocol }, -admin => $admin );

    $self->param( 'Protocol'      => $Protocol );
    $self->param( 'Protocol_View' => $Protocol_View );
    $self->param( 'dbc'           => $dbc );
    $self->param( 'Admin'         => $admin );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}

################
sub home_page {
################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $admin    = $self->param('Admin');
    my $protocol = $q->param('Protocol') || $q->param('Protocol Choice')  || $q->param('FK_Lab_Protocol__ID');
    $protocol =~ s/\+/ /g;

    return $self->param('Protocol_View')->home_page( -dbc => $dbc, -protocol => $protocol, -admin => $admin );

}

################
sub create_protocol_prompt {
################
    my $self  = shift;
    my $q     = $self->query();
    my $dbc   = $self->param('dbc');
    my $admin = $self->param('Admin');

    return $self->param('Protocol_View')->new_protocol_prompt( -dbc => $dbc, -admin => $admin );
}

################
sub delete_Protocol {
################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $admin    = $self->param('Admin');
    my $protocol = $q->param('Protocol Choice') || $q->param('Protocol')  || $q->param('FK_Lab_Protocol__ID');
    if ($protocol) {
        $self->param('Protocol')->delete_Protocol( -protocol => $protocol, -dbc => $dbc, -admin => $admin );
    }

    return $self->param('Protocol_View')->home_page( -dbc => $dbc, -admin => $admin );

}

################
sub edit_Protocol_Visibility {
################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $admin    = $self->param('Admin');
    my $protocol = $q->param('Protocol Choice') || $q->param('Protocol')  || $q->param('FK_Lab_Protocol__ID');

    return $self->param('Protocol_View')->edit_Protocol_Visibility( -dbc => $dbc, -admin => $admin, -protocol => $protocol );

}

################
sub save_step_details {
################
    my $self              = shift;
    my $q                 = $self->query();
    my $dbc               = $self->param('dbc');
    my $admin             = $self->param('Admin');
    my $protocol          = $q->param('Protocol Choice') || $q->param('Protocol')  || $q->param('FK_Lab_Protocol__ID');
    my $step_number       = $q->param('Step Number');
    my $step_type         = $q->param('Step_Type');
    my $format            = $q->param('Step_Format') || '';
    my $new_sample_type   = $q->param('New_Sample_Type') || '';
    my $create_new_sample = $q->param('Create_New_Sample') || '';
    my $step_name         = $q->param('Step_Name');
    my $new_message       = $q->param('Message');
    my $new_instructions  = $q->param('Step Instructions');
    my $new_qc_attribute  = $q->param('QC_Attribute');
    my $validate          = $q->param('Validate');
    my $new_qc_condition  = $q->param('QC_Condition');
    my $step_id           = $q->param('Step_ID');
    my @extra_inputs      = $q->param('Input');
    my @prep_attr_def     = $q->param('Prep_Attribute_Def');
    my @prep_attr_name    = $q->param('Prep Attributes');
    my @plate_attr_def    = $q->param('Plate_Attribute_Def');
    my @plate_attr_name   = $q->param('Plate Attributes');
    my @list              = $q->param('Reagents');
    my $plate_label_def   = $q->param('Plate_Label_def');
    my $transfer_q        = $q->param('Transfer_Quantity') || '';
    my $transfer_q_unit   = $q->param('Transfer_Quantity_Units') || 'ml';
    my $split_x           = $q->param('Split_X');
    my @mformats_chosen   = $q->param('MFormat');
    my $quantity          = $q->param('Quantity') || '';
    my $quantity_units    = $q->param('Quantity_Units') || '';
    my $sformat           = $q->param('SFormat') || '';
    my $new_scanner;
    if   ( $q->param('Scanner') ) { $new_scanner = 1 }
    else                          { $new_scanner = 0 }
    my $new_qc_attr_id;
    $new_qc_attr_id = $dbc->get_FK_ID( 'FKQC_Attribute__ID', $new_qc_attribute ) if $new_qc_attribute;

    ## Gotta make sure sample type is set for extract
    if ( $step_type =~ /extract/i && !$new_sample_type ) {
        Message("Error: Sample type is mandatory for extract steps");
        return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
    }

    my $new_step_name = $self->param('Protocol')->get_New_Step_Name( -step_type => $step_type, -format => $format, -new_sample_type => $new_sample_type, -create_new_sample => $create_new_sample, -step_name => $step_name );

    ### Does name already exist in protocol

    my $condition = "WHERE FK_Lab_Protocol__ID= Lab_Protocol_ID AND Lab_Protocol_Name = '$protocol' AND Protocol_Step_name='$new_step_name'";
    if ($step_id) {
        $condition .= " AND Protocol_Step_ID <> $step_id";
    }
    my ($existing_name) = $dbc->Table_find( 'Protocol_Step,Lab_Protocol', 'Protocol_Step_ID', $condition );
    if ($existing_name) {
        Message("Error: '$new_step_name' already exists as an step in this Protocol. Please use a different name or change that");
        return $self->param('Protocol_View')->home_page( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
    }

    ### Cannot repeat same attribute
    my @unique_prep_attr_names  = @{ unique_items( \@prep_attr_name ) };
    my @unique_plate_attr_names = @{ unique_items( \@plate_attr_name ) };
    if ( @unique_prep_attr_names != @prep_attr_name ) {
        Message("Error: Can not specify duplicate Prep attributes for a given step");
        return $self->param('Protocol_View')->home_page( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
    }
    elsif ( @unique_plate_attr_names != @plate_attr_name ) {
        Message("Error: Can not specify duplicate Plate attributes for a given step");
        return $self->param('Protocol_View')->home_page( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
    }

    my ( $inputs, $defaults, $formats ) = $self->param('Protocol')->get_Formatted_Values(
        -plate_label_def => $plate_label_def,
        -transfer_q      => $transfer_q,
        -transfer_q_unit => $transfer_q_unit,
        -split_x         => $split_x,
        -mformats_chosen => \@mformats_chosen,
        -quantity        => $quantity,
        -quantity_units  => $quantity_units,
        -sformat         => $sformat,
        -list            => \@list,
        -extra_inputs    => \@extra_inputs,
        -prep_attr_name  => \@prep_attr_name,
        -prep_attr_def   => \@prep_attr_def,
        -plate_attr_name => \@plate_attr_name,
        -plate_attr_def  => \@plate_attr_def,
        -step_number     => $step_number
    );
    my $date    = today();
    my $user_id = $dbc->get_local('user_id');
    my @fields  = (
        'Protocol_Step_Number', 'Protocol_Step_Name',     'Scanner',      'Protocol_Step_Message', 'Protocol_Step_Instructions', 'FKQC_Attribute__ID', 'QC_Condition', 'Validate',
        'Input',                'Protocol_Step_Defaults', 'Input_Format', 'FK_Employee__ID',       'Protocol_Step_Changed'
    );
    my @new_values = ( $step_number, $new_step_name, $new_scanner, $new_message, $new_instructions, $new_qc_attr_id, $new_qc_condition, $validate, $inputs, $defaults, $formats, $user_id, $date );

    if ($step_id) {
        Message "editing";
        my $ok = $dbc->Table_update_array( 'Protocol_Step', \@fields, \@new_values, "where Protocol_Step_ID=$step_id", -autoquote => 1 );
        $self->param('Protocol')->reindex_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -id => $step_id );

    }
    else {
        my ($protocol_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "WHERE Lab_Protocol_Name = '$protocol'" );
        push @fields,     'FK_Lab_Protocol__ID';
        push @new_values, $protocol_id;
        my $id = $dbc->Table_append_array( 'Protocol_Step', \@fields, \@new_values, -autoquote => 1, -quiet => 1 );
        $self->param('Protocol')->reindex_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -id => $id );
    }

    return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
}

################
sub update_Protocol_Access {
################
    my $self            = shift;
    my $q               = $self->query();
    my $dbc             = $self->param('dbc');
    my $admin           = $self->param('Admin');
    my $protocol        = $q->param('Protocol Choice') || $q->param('Protocol')  || $q->param('FK_Lab_Protocol__ID');
    my @selected_groups = $q->param('GrpLab_Protocol');

    unless (@selected_groups) {
        @selected_groups = $q->param('GrpLab_Protocol Choice');
    }

    my $access_groups = $dbc->get_local('groups');
    my @access_groups;
    @access_groups = @$access_groups if $access_groups;

    my $access_ids   = $dbc->get_FK_ID( 'FK_Grp__ID',          \@access_groups );
    my $selected_ids = $dbc->get_FK_ID( 'FK_Grp__ID',          \@selected_groups );
    my $protocol_id  = $dbc->get_FK_ID( 'FK_Lab_Protocol__ID', $protocol );
    my @curent_grp_ids = $dbc->Table_find( 'GrpLab_Protocol', 'FK_Grp__ID', "WHERE FK_Lab_Protocol__ID = $protocol_id" );

    my @selected_ids, my @access_ids;
    @selected_ids = @$selected_ids if $selected_ids;
    @access_ids   = @$access_ids   if $access_ids;

    ## ADD = SELECT - CURRENT
    my @add_groups = RGmath::minus( \@selected_ids, \@curent_grp_ids );
    my $add = join ',', @add_groups;

    ## DELETE = COMMON (CURRENT , (ACCESS  - SELECTED))
    my @temp = RGmath::minus( \@access_ids, \@selected_ids );
    my $delete_groups;
    ($delete_groups) = RGmath::intersection( \@curent_grp_ids, \@temp );
    my @delete_groups;
    @delete_groups = @$delete_groups if $delete_groups;

    foreach my $join_grp (@add_groups) {
        $dbc->Table_append_array( 'GrpLab_Protocol', [ 'FK_Lab_Protocol__ID', 'FK_Grp__ID' ], [ $protocol_id, $join_grp ], -no_triggers => 1 );
    }

    foreach my $delete (@delete_groups) {
        $dbc->delete_record( 'GrpLab_Protocol', 'FK_Lab_Protocol__ID', $protocol_id, -condition => "FK_Grp__ID IN ($delete)" );
    }

    return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -admin => $admin, -protocol => $protocol );

}

################
sub save_new_protocol {
################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $admin    = $self->param('Admin');
    my $desc     = $q->param('Protocol Description');
    my $protocol = $q->param('New Protocol Name');
    my @groups   = $q->param('GrpLab_Protocol Choice');
    my $invoiced = $q->param('invoiced');

    $protocol =~ s/\+/ /g;
    my $groups_ref;
    $groups_ref = get_FK_ID( $dbc, 'FK_Grp__ID', \@groups );
    my @group_ids;
    @group_ids = @{$groups_ref} if ($groups_ref);

    #add new protocol in DB
    $self->param('Protocol')->new_protocol( -protocol => $protocol, -description => $desc, -group_ids => \@group_ids, -dbc => $dbc, -admin => $admin );

    if ($invoiced) {

        #if users check 'Invoiced' checkbox, add new lab protocol and invoice protocol pair in DB
        #input: Invoice protocol, Invoice protocol type, new lab protocol ID FK_Lab_Protocol__ID, Invoice_Protocol_Status, Tracked_Prep_Name
        my @FK_Lab_Protocol__ID   = $dbc->Table_find( 'Lab_Protocol', "Lab_Protocol_ID", "where Lab_Protocol_Name = '$protocol'", -distinct => 1 );
        my @invoice_protocol      = $q->param('Invoice_Protocol Choice');
        my @invoice_protocol_type = $q->param('Invoice_Protocol_Type Choice');
        my @Tracked_Prep_Name     = $q->param('Tracked_Prep_Name Choice');
        my @Invoice_status        = $q->param('Invoice_status Choice');

        my $invoice_protocol = $dbc->Table_append(
            "Invoice_Protocol",
            'Invoice_Protocol_Name, Invoice_Protocol_Type, FK_Lab_Protocol__ID,Tracked_Prep_Name,Invoice_Protocol_Status',
            "@invoice_protocol, @invoice_protocol_type, @FK_Lab_Protocol__ID, @Tracked_Prep_Name, @Invoice_status",
            -autoquote => 1
        );
    }

    return $self->param('Protocol_View')->home_page( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
}

################
sub update_Protocol_Name {
################
    my $self              = shift;
    my $q                 = $self->query();
    my $dbc               = $self->param('dbc');
    my $admin             = $self->param('Admin');
    my $new_protocol_name = $q->param('Protocol Name');
    my $old_protocol_name = $q->param('Protocol Choice') || $q->param('Protocol');

    if ( !$new_protocol_name ) {
        Message "No name supplied";

    }
    else {
        my ($new_protocol_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = '$new_protocol_name'", -debug => 0 );
        if ($new_protocol_id) {
            Message("There is already another Lab Protocol with the new name you specified($new_protocol_name)");

        }
        else {
            $dbc->start_trans( -name => 'Edit Protocol Name' );
            my ($old_protocol_id) = $dbc->get_FK_ID( 'FK_Lab_Protocol__ID', $old_protocol_name );

            my $result = $dbc->Table_update(
                'Lab_Protocol', 'Lab_Protocol_Name', $new_protocol_name,
                -condition => "where lab_protocol_id = $old_protocol_id",
                -debug     => 0,
                -autoquote => 1
            );
            $dbc->finish_trans( -name => 'Edit Protocol Name' );
            Message "Changed protocol name from '$old_protocol_name' to '$new_protocol_name' ";
        }
    }

    return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -admin => $admin, -protocol => $new_protocol_name );

}

################
sub change_Protocol_Status {
################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $admin    = $self->param('Admin');
    my $protocol = $q->param('Protocol Choice') || $q->param('Protocol')  || $q->param('FK_Lab_Protocol__ID');
    my $status   = $q->param('State');

    my $protocol_obj = new alDente::Protocol( -dbc => $dbc );
    my $old_status = $protocol_obj->get_protocol_status( -name => $protocol );
    my $ok = $protocol_obj->set_protocol_status( -name => $protocol, -status => $status );
    if   ($ok) { Message("Status Set to <B>$status</B>"); }
    else       { Message("Status was not affected"); }

    ## generate notification to admins if TechD protocols changed from 'Under Development' to 'Active'
    if ( $old_status eq 'Under Development' && $status eq 'Active' ) {
        require alDente::Admin;
        alDente::Admin::send_status_change_notification( -dbc => $dbc, -type => 'Protocol', -name => $protocol );
    }

    return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
}

################
sub delete_step {
################
    my $self         = shift;
    my $q            = $self->query();
    my $dbc          = $self->param('dbc');
    my $admin        = $self->param('Admin');
    my $protocol     = $q->param('Protocol') || $q->param('Protocol Choice') || $q->param('FK_Lab_Protocol__ID');
    my $current_step = $q->param('Current_Step');

    $self->param('Protocol')->delete_Steps( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -steps => $current_step );
    $self->param('Protocol')->reindex_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin );

    return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
}

################
sub step_Actions {
################
    my $self        = shift;
    my $q           = $self->query();
    my $dbc         = $self->param('dbc');
    my $admin       = $self->param('Admin');
    my $allow_edit  = $q->param('Allow_Edit');
    my $protocol    = $q->param('Protocol') || $q->param('Protocol Choice')  || $q->param('FK_Lab_Protocol__ID');
    my $delete      = $q->param('Delete Step(s)');
    my $edit_step   = $q->param('Step Details');
    my $add_step    = $q->param('Add Step');
    my $step_number = $q->param('step_number');
    my $step_name   = $q->param('Step');

    my ($step_count) = $dbc->Table_find( 'Protocol_Step, Lab_Protocol', 'count(Protocol_Step_ID)', "WHERE FK_Lab_Protocol__ID = Lab_Protocol_ID and Lab_Protocol_Name = '$protocol'" );

    if ($delete) {
        my @delete_steps;
        for my $index ( 1 .. $step_count ) {
            if ( $q->param( 'Delete_' . $index ) ) { push @delete_steps, $index }
        }
        my $steps = join ',', @delete_steps;
        if ($steps) {
            $self->param('Protocol')->delete_Steps( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -steps => $steps );
            $self->param('Protocol')->reindex_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
        }
        else { Message "No steps specified" }
        return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin );

    }
    elsif ($add_step) {
        $step_number ||= $step_count + 1;
        return $self->param('Protocol_View')->display_Step_Page( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -allow_edit => $allow_edit, -new_step => 1, -step_number => $step_number );
    }
    elsif ($edit_step) {
        my $preset = $self->get_step_presets( -dbc => $dbc, -protocol => $protocol, -step_number => $step_number );
        return $self->param('Protocol_View')->display_Step_Page( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -allow_edit => $allow_edit, -step_number => $step_number, -preset => $preset );
    }
    else {
        ($step_number) = $dbc->Table_find( 'Protocol_Step, Lab_Protocol', 'Protocol_Step_Number', " WHERE FK_Lab_Protocol__ID = Lab_Protocol_ID and Lab_Protocol_Name = '$protocol' and Protocol_Step_Name = '$step_name'" );
        my $preset = $self->get_step_presets( -dbc => $dbc, -protocol => $protocol, -step_number => $step_number );
        return $self->param('Protocol_View')->display_Step_Page( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -allow_edit => $allow_edit, -step_number => $step_number, -preset => $preset );
    }
}

################
sub save_as_new_protocol_View {
################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $admin    = $self->param('Admin');
    my $protocol = $q->param('Protocol') || $q->param('Protocol Choice')  || $q->param('FK_Lab_Protocol__ID');

    return $self->param('Protocol_View')->save_New_Protocol_View( -dbc => $dbc, -protocol => $protocol, -admin => $admin );

}

################
sub save_as_new_protocol {
################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $admin    = $self->param('Admin');
    my $protocol = $q->param('Protocol') || $q->param('Protocol Choice') || $q->param('FK_Lab_Protocol__ID');
    my $newname  = $q->param('New Name');
    my $newgroup = $q->param('New Group');
    my $active   = $q->param('Active');
    my $state;
    if   ($active) { $state = "Active" }
    else           { $state = 'Under Development' }

    if ( !$newname ) {
        Message "No new name supplied!";
        return $self->param('Protocol_View')->save_New_Protocol_View( -dbc => $dbc, -protocol => $protocol, -admin => $admin );

    }
    ## saving action goes here
    my $success = $self->param('Protocol')->copy_protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -new_name => $newname, -new_group => $newgroup, -state => $state );

    if ( !$success ) {
        return $self->param('Protocol_View')->save_New_Protocol_View( -dbc => $dbc, -protocol => $protocol, -admin => $admin );
    }

    return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -protocol => $newname, -admin => $admin );

}

################
sub view_protocol {
################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $admin    = $self->param('Admin');
    my $protocol = $q->param('Protocol') || $q->param('Lab_Protocol Choice') || $q->param('Lab_Protocol') || $q->param('FK_Lab_Protocol__ID');
    my $instr    = $q->param('Include Instructions');

    if ( !$protocol || $protocol eq '-' ) {
        $dbc->message("No protocol was selected");
        return;
    }

    $protocol =~ s/\+/ /g;

    return $self->param('Protocol_View')->view_Protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -instructions => $instr );

}

######################################

#####################
sub get_step_presets {
#####################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->param('dbc');
    my $protocol    = $args{-protocol};
    my $step_number = $args{-step_number};

    my @fields = ( 'Protocol_Step_Number', 'Protocol_Step_ID', 'Protocol_Step_Name', 'Protocol_Step_Instructions', 'Protocol_Step_Defaults', 'Input', 'Scanner', 'Protocol_Step_Message', 'Input_Format', 'FKQC_Attribute__ID', 'QC_Condition', 'Validate' );
    my %Presets = $dbc->Table_retrieve( "Protocol_Step, Lab_Protocol", \@fields, "WHERE FK_Lab_Protocol__ID = Lab_Protocol_ID and Lab_Protocol_Name = '$protocol' and Protocol_Step_Number = $step_number" );

    my @inputs, my @defaults, my @formats;
    @inputs   = split ':', join( ',', $Presets{Input}[0] )                  if $Presets{Input}[0];
    @defaults = split ':', join( ',', $Presets{Protocol_Step_Defaults}[0] ) if $Presets{Protocol_Step_Defaults}[0];
    @formats  = split ':', join( ',', $Presets{Input_Format}[0] )           if $Presets{Input_Format}[0];
    my @plateattr_pos;
    my @prepattr_pos;

    for my $count ( 0 .. $#inputs ) {
        if ( $inputs[$count] =~ /Mixture\((\d+)\)/ ) {
            $Presets{Mix}[0] = [$1];

            #$mix = $1;    # the number of mixture of reagents
        }
        elsif ( $inputs[$count] =~ /Solution_Quantity/ ) {
            $Presets{Quant_Position}[0] = $count;
        }
        elsif ( $inputs[$count] =~ /FK_Equipment__ID/ ) {
            $Presets{Equipment_Position}[0] = $count;
        }
        elsif ( $inputs[$count] =~ /FK_Solution__ID/ ) {
            $Presets{Solution_Position}[0] = $count;
        }
        elsif ( $inputs[$count] =~ /FK_Rack__ID/ ) {
            $Presets{Rack_Position}[0] = $count;
        }
        elsif ( $inputs[$count] =~ /Track_Transfer/ ) {
            $Presets{Track_Position}[0] = $count;
        }
        elsif ( $inputs[$count] =~ /Plate_Label/ ) {
            $Presets{Label_Position}[0] = $count;
        }
        elsif ( $inputs[$count] =~ /Split/ ) {
            $Presets{Split_Position}[0] = $count;
        }
        elsif ( $inputs[$count] =~ /Plate_Attribute/ ) {
            push( @plateattr_pos, $count );
        }
        elsif ( $inputs[$count] =~ /Prep_Attribute/ ) {
            push( @prepattr_pos, $count );
        }
    }

    $Presets{Plate_Attribute_Position} = \@plateattr_pos;
    $Presets{Prep_Attribute_Position}  = \@prepattr_pos;
    $Presets{Input}                    = \@inputs;
    $Presets{Defaults}                 = \@defaults;
    $Presets{Formats}                  = \@formats;

    return \%Presets;
}

###########################
# Accept TechD protocols
###########################
sub accept_protocol {
###########################
    my $self     = shift;
    my $q        = $self->query();
    my $dbc      = $self->param('dbc');
    my $protocol = $q->param('Lab_Protocol Choice') || $q->param('Protocol');
    $protocol =~ s/\+/ /g;

    my $Current_Department = $dbc->config('Target_Department');

    if ( !$protocol ) {
        Message("No protocol selected");
        return;
    }
    if ( !grep( /Admin/i, @{ $dbc->get_local('Access')->{$Current_Department} } ) ) {
        Message("Please ask $Current_Department Admins to accept the protocol");
        return;
    }

    ## assign 'Admin' Grp_Access to the production grp
    #my $protocol_id = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = '$protocol'" );
    my $protocol_id = $dbc->get_FK_ID( 'FK_Lab_Protocol__ID', $protocol );

    my $protocol_obj = new alDente::Protocol( -dbc => $dbc, -id => $protocol_id );

    my $grp_access = $protocol_obj->get_grp_access( -dbc => $dbc, -name => $protocol );
    my $depart_id = $dbc->get_FK_ID( 'FK_Department__ID', $Current_Department );
    my @prod_grps;
    @prod_grps = alDente::Grp::get_Grps( -dbc => $dbc, -department => $depart_id, -type => 'Production', -format => 'ids' );
    my $production_grp;
    $production_grp = $prod_grps[0] if ( int(@prod_grps) );
    my $access = 'Admin';    # assign 'Admin' permission to the production grp
    my $ok_prod;

    if ( grep /^$production_grp$/, keys %$grp_access ) {
        if ( $grp_access->{$production_grp} eq 'Admin' ) {

            # admin permission already. Do nothing
            $ok_prod = 1;
        }
        else {               # update Grp_Access to 'Admin'
            $ok_prod = $dbc->Table_update_array( 'GrpLab_Protocol', ['Grp_Access'], [$access], "where FK_Lab_Protocol__ID = $protocol_id and FK_Grp__ID = $production_grp ", -autoquote => 1 );
        }
    }
    else {                   # associate production grp with the protocol
        $ok_prod = $dbc->Table_append_array( 'GrpLab_Protocol', [ 'FK_Grp__ID', 'FK_Lab_Protocol__ID', 'Grp_Access' ], [ $production_grp, $protocol_id, $access ], -autoquote => 1 );
    }

    ## assign 'Read-only' Grp_Access to the TechD grp
    my @techD_grps = alDente::Grp::get_Grps( -dbc => $dbc, -department => $depart_id, -type => 'TechD', -format => 'ids' );
    my $techD_grp;
    $techD_grp = $techD_grps[0] if ( int(@techD_grps) );

    my $ok_techD = $dbc->Table_update_array( 'GrpLab_Protocol', ['Grp_Access'], ['Read-only'], "where FK_Lab_Protocol__ID = $protocol_id and FK_Grp__ID = $techD_grp ", -autoquote => 1 );

    my $grp_name = $dbc->get_FK_info( 'FK_Grp__ID', $production_grp );
    if ( $ok_prod && $ok_techD ) {
        Message("$protocol has been accepted by $grp_name successfully.");
        return 1;
    }
    else {
        Message("Error: Accepting $protocol by $grp_name hasn't been completed.");
        return 0;
    }

}

sub send_notification {
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'dbc,protocol_name' );
    my $dbc      = $args{-dbc};
    my $protocol = $args{-protocol_name};

    my $protocol_obj = new alDente::Protocol( -dbc => $dbc );
    my $grp_access = $protocol_obj->get_grp_access( -dbc => $dbc, -name => $protocol );
    foreach my $grp ( keys %$grp_access ) {
        my ($info) = $dbc->Table_find( 'Grp', 'Grp_Name,Grp_Type,FK_Department__ID', "Where Grp_ID = $grp" );
        my ( $name, $type, $department ) = split ',', $info;
        if ( ( $type eq 'TechD' ) && ( $grp_access->{$grp} eq 'Admin' ) ) {    # TechD protocol becomes active
            require alDente::Subscription;                                     ## Subscription module.
            my $msg = "The following lab protocol has been approved by $name. Please go to Admin page to accept the protocol.\n\n";
            $msg .= "<P><B>" . $protocol . "</B><P>";
            my $subscription_event_name = 'Approved TechD Protocols';
            my $from_name               = 'Genome Sciences Centre LIMS';
            my $from_email              = 'aldente';

            # send notification
            my $ok = alDente::Subscription::send_notification(
                -dbc          => $dbc,
                -name         => $subscription_event_name,
                -from         => "$from_name <$from_email>",
                -subject      => "Approved TechD Protocol - $protocol",
                -body         => $msg,
                -content_type => 'html',
                -group        => [$grp],
            );
            if ($ok) {
                Message("Approved TechD Protocol notification successfully sent.");
            }
            else {
                Message("Failed to send Approved TechD Protocol notification to the admins.");
            }
        }
    }
}
return 1;


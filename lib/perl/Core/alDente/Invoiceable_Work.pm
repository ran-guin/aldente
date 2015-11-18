###################################################################################################################################
# Sequencing::Template.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Invoiceable_Work;

use base SDB::DB_Object;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
## alDente modules
use alDente::Invoice_Views;

use vars qw( %Configs );

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Invoiceable_Work' );
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'Invoiceable_Work', -value => $id );
        $self->load_Object();
    }

    return $self;
}

##############################
# Temporary method for validating if Work_Request, Invoiceable_Work or IWR should be changed
# FKApplicable_Funding__ID of all IWR in a tree should be equal before changes are allowed
# Else changes should not be made
#
# Input: Invoiceable_Work_id, should be stored in object
##############################
sub validate_IWR_funding_update {
##############################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $IW_id = $args{-id};

    my @IWRs = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID = $IW_id" );
    my $IWR_ids = Cast_List( -list => \@IWRs, -to => 'String' );
    my @FKApplicable_Funding__ID = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference.FKApplicable_Funding__ID', "WHERE Invoiceable_Work_Reference_ID IN ($IWR_ids)" );

    my %string = map { $_, 1 } @FKApplicable_Funding__ID;

    if ( keys %string > 2 ) {
        $dbc->warning("Invoiceable_Work_References have different Funding, may be incorrect to set them all the same");

        return 0;
    }
    elsif ( keys %string == 2 && !( $string{""} ) ) {
        $dbc->warning("Invoiceable_Work_References have different Funding, may be incorrect to set them all the same");
        return 0;
    }
    else {
        if ( $string{""} ) {
            $dbc->warning("WARNING: Invoiceable_Work_References have FKApplicable_Funding__ID as Null");
        }
        return 1;
    }
}

##############################
# Changes the billable status of the Invoiceable Work
# This change is then reflected in the runs table
#
# Input: whether this is for the views or not
#Output: An HTML button
##############################
sub change_billable_btn {
##############################
    my %args              = filter_input( \@_, -args => 'dbc' );
    my $dbc               = $args{-dbc};
    my $from_views        = $args{-from_view};                     # A parameter that needs to be set if this button is being used in a view.
    my $validation_filter = '';

    if ($from_views) {
        $validation_filter .= "this.form.target='_blank';sub_cgi_app( 'alDente::Invoiceable_Work_App');";
    }

    #    $validation_filter .= "unset_mandatory_validators(this.form);";
    $validation_filter .= "unset_mandatory_validators(this.form); document.getElementById('billable_validator').setAttribute('mandatory',1);";
    $validation_filter .= "document.getElementById('billable_comments_validator').setAttribute('mandatory',1);";
    $validation_filter .= "return validateForm(this.form)";

    my $form_output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Change Billable Status', -class => 'Action', -onClick => "$validation_filter", -force => 1 ),
        "Changes billable status. Creates a new window. Will send an notification email if item is invoiced. " );

    if ($from_views) {
        $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );
    }
    else {
        $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoiceable_Work_App', -force => 1 );
    }

    $form_output .= hspace(10) . popup_menu( -name => 'Billable', -id => 'Billable', -values => [ '', get_enum_list( $dbc, 'Invoiceable_Work_Reference', 'Billable' ) ], -force => 1 );
    $form_output .= set_validator( -name => 'Billable', -id => 'billable_validator' );
    $form_output .= " Billable Comments: " . textfield( -name => 'Billable_Comments', -size => 30, -default => '' );
    $form_output .= set_validator( -name => 'Billable_Comments', -id => 'billable_comments_validator' );

    return $form_output;
}

###############################
# A button that is used to set the funding
# Input: Whether it is from the views or not
# Input: the library_Name
#
# Output: An HTML Button
##############################
sub set_funding_btn {
##############################

    my %args              = filter_input( \@_, -args => 'dbc' );
    my $dbc               = $args{-dbc};
    my $from_view         = $args{-from_view};                     # A parameter that needs to be set if this button is being used in a view.
    my $library           = $args{-library};
    my $validation_filter = '';
    my $funding_list;

    if ($from_view) {
        $validation_filter .= "this.form.target='_blank';sub_cgi_app( 'alDente::Invoiceable_Work_App');";
    }

    #    $validation_filter    .= "unset_mandatory_validators(this.form);";
    $validation_filter .= "document.getElementById('funding_validator').setAttribute('mandatory',1);";
    $validation_filter .= "return validateForm(this.form)";

    my $form_output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Set Funding', -class => 'Action', -onClick => "$validation_filter", -force => 1 ), "Sets applicable funding of invoiceable work item" );
    $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoiceable_Work_App', -force => 1 );

    if ($from_view) {
        $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );
    }
    else {
        $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoiceable_Work_App', -force => 1 );
    }

    my @funding_parent = $dbc->Table_find_array( "Work_Request", ['FK_Funding__ID'], "WHERE FK_Library__Name = '$library' AND FK_Funding__ID IS NOT NULL", -distinct => 1 );
    my $funding_parent_string = Cast_List( -list => \@funding_parent, -to => 'string' );
    my @funding_children = $dbc->Table_find_array(
        "Work_Request, Plate Parent, Plate Child, ReArray, ReArray_Request",
        ['FK_Funding__ID'],
        "WHERE Parent.FK_Library__Name = '$library' AND ReArray_Request.FKTarget_Plate__ID = Parent.Plate_ID AND ReArray.FK_ReArray_Request__ID = ReArray_Request_ID AND ReArray.FKSource_Plate__ID = Child.Plate_ID AND Child.FK_Library__Name = Work_Request.FK_Library__Name AND FK_Funding__ID NOT IN ($funding_parent_string)",
        -distinct => 1
    );
    my @funding = ( @funding_parent, @funding_children );
    my $funding_values = Cast_List( -list => \@funding, -to => 'string' );

    if ($funding_values) {

        $funding_list = "  Funding: " . &alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Funding__ID', -filter_by_dept => 1, -search => 1, -filter => 1, -condition => "WHERE Funding_ID in ($funding_values)" );
    }
    else {

        $funding_list = "  Funding: " . &alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Funding__ID', -filter_by_dept => 1, -search => 1, -filter => 1 );

    }

    $form_output .= hspace(10) . $funding_list;
    $form_output .= set_validator( -name => 'Funding', -id => 'funding_validator' );

    return $form_output;
}

#####################
# This function is used in the views to get more information about the work item
#
# Input: Invoiceable_Work_ID
# Output: HTML string of the information
#
#####################
sub get_work_info {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my $info;

    ## Getting basic information about the invoiceable_work item
    my ($initial_data) = $dbc->Table_find(
        'Invoiceable_Work IW LEFT JOIN Plate ON Plate_ID = IW.FK_Plate__ID LEFT JOIN Multiplex_Run_Analysis MRA ON IW.FK_Multiplex_Run_Analysis__ID = MRA.Multiplex_Run_Analysis_ID LEFT JOIN Run_Analysis RA ON IW.FK_Run_Analysis__ID = RA.Run_Analysis_ID LEFT JOIN Sample MRA_Sample ON MRA_Sample.Sample_ID = MRA.FK_Sample__ID LEFT JOIN Sample RA_Sample ON RA_Sample.Sample_ID = RA.FK_Sample__ID LEFT JOIN Library ON Library_Name = COALESCE(Plate.FK_Library__Name, MRA_Sample.FK_Library__Name, RA_Sample.FK_Library__Name) LEFT JOIN Plate_Attribute ON Plate_Attribute.FK_Plate__ID = Plate.Plate_ID AND Plate_Attribute.FK_Attribute__ID = 246 LEFT JOIN Library_Strategy ON Plate_Attribute.Attribute_Value = Library_Strategy.Library_Strategy_ID',
        'IW.Invoiceable_Work_Type, Library_Strategy.Library_Strategy_Name, Library.Library_Name, IW.Invoiceable_Work_DateTime, Plate.Plate_ID',
        "WHERE IW.Invoiceable_Work_ID in ($id)"
    );

    my ( $work_type, $lib_strat, $lib, $date, $plate ) = split ',', $initial_data;

    my $lib_link   = &Link_To( $dbc->config('homelink'), "$lib",   "&HomePage=Library&ID=$lib" );
    my $plate_link = &Link_To( $dbc->config('homelink'), "$plate", "&HomePage=Plate&ID=$plate" );

    ## Filling out the top section of the homepage ##
    $info .= "<b>Work Type:</b> $work_type <br>" . "<b>Library Strategy:</b> $lib_strat <br>" . "<b>Associated Library:</b> $lib_link <br>" . "<b>Plate:</b> $plate_link<br><br>" . "<b>Work Done On: </b> $date <br><br>";

    ## This will fill out the remain top portion of the homepage with relevant information
    ## The information will depend on whether the Invoiceable_Work_Type is an analysis, prep, or run
    if ( $work_type eq 'Prep' ) {

        ## Getting relevant information to fill out
        my ($prep_info) = $dbc->Table_find(
            'Invoiceable_Prep IPR, Invoice_Protocol IP, Lab_Protocol',
            'IPR.FK_Prep__ID, IP.FK_Lab_Protocol__ID, Lab_Protocol.Lab_Protocol_Name, IP.Invoice_Protocol_Name',
            "WHERE FK_Invoiceable_Work__ID = $id AND IPR.FK_Invoice_Protocol__ID = IP.Invoice_Protocol_ID AND IP.FK_Lab_Protocol__ID = Lab_Protocol.Lab_Protocol_ID"
        );

        my ( $prep_id, $lab_protocol, $lab_protocol_name, $protocol_name ) = split ',', $prep_info;

        my $protocol_link = &Link_To( $dbc->config('homelink'), "$lab_protocol_name", "&HomePage=Lab_Protocol&ID=$lab_protocol" );
        my $prep_link     = &Link_To( $dbc->config('homelink'), "$prep_id",           "&HomePage=Prep&ID=$prep_id" );

        $info .= "<h2>Prep Info</h2>" . "<b>Prep ID:</b> $prep_link<br>" . "<b>Lab Protocol:</b> $protocol_link<br>" . "<b>Work Type:</b> $protocol_name<br>";
    }
    elsif ( $work_type eq 'Run' ) {

        ## Getting relevant information to fill out
        my ($run_info) = $dbc->Table_find(
            'Invoiceable_Run, Invoice_Run_Type IRType, Run, RunBatch, Equipment LEFT JOIN Solexa_Read ON Solexa_Read.FK_Run__ID= Run.Run_ID',
            'Run.Run_ID, IRType.Invoice_Run_Type_Name, Equipment.Equipment_ID, Equipment.Equipment_Name, CONCAT(Solexa_Read.Read_Length , \' bp \' , Left(Solexa_Read.End_Read_Type , 1) , \'ET\')  AS Run_Type',
            "WHERE Invoiceable_Run.FK_Invoiceable_Work__ID = $id AND Invoiceable_Run.FK_Invoice_Run_Type__ID = IRType.Invoice_Run_Type_ID AND Invoiceable_Run.FK_Run__ID = Run.Run_ID AND Run.FK_RunBatch__ID = RunBatch.RunBatch_ID AND RunBatch.FK_Equipment__ID = Equipment.Equipment_ID AND ( Solexa_Read.End_Read_Type IS NULL OR Solexa_Read.End_Read_Type NOT LIKE 'IDX%' )"
        );

        my ( $run_id, $run_type, $machine_id, $machine_name, $run_details ) = split ',', $run_info;

        my $run_link       = &Link_To( $dbc->config('homelink'), "$run_id",       "&HomePage=Run&ID=$run_id" );
        my $equipment_link = &Link_To( $dbc->config('homelink'), "$machine_name", "&HomePage=Equipment&ID=$machine_id" );

        $info .= "<h2>Run Info</h2>" . "<b>Run ID:</b> $run_link<br>" . "<b>Run Type:</b> $run_type<br>" . "<b>Run Details:</b> $run_details<br>" . "<b>Machine:</b> $equipment_link";
    }
    elsif ( $work_type eq 'Analysis' ) {
        my ($analysis_info) = $dbc->Table_find(
            'Invoiceable_Run_Analysis IRA, Invoice_Pipeline IP, Pipeline',
            'IRA.FK_Run_Analysis__ID, IRA.FK_Multiplex_Run_Analysis__ID, IP.FK_Pipeline__ID, Pipeline.Pipeline_Name, IP.Invoice_Pipeline_Name',
            "WHERE IRA.FK_Invoice_Pipeline__ID = IP.Invoice_Pipeline_ID AND Pipeline_ID = IP.FK_Pipeline__ID AND IRA.FK_Invoiceable_Work__ID = $id"
        );
        ## Getting relevant information to fill out
        my ( $ra_id, $mra_id, $pipeline, $pipeline_name, $invoice_pipeline_name ) = split ',', $analysis_info;

        my $ra_link       = &Link_To( $dbc->config('homelink'), "$ra_id",         "&HomePage=Run_Analysis&ID=$ra_id" );
        my $mra_link      = &Link_To( $dbc->config('homelink'), "$mra_id",        "&HomePage=Multiplex_Run_Analysis&ID=$mra_id" );
        my $pipeline_link = &Link_To( $dbc->config('homelink'), "$pipeline_name", "&HomePage=Pipeline&ID=$pipeline" );

        $info .= "<h2>Analysis Info</h2>" . "<b>Run Analysis ID:</b> $ra_link<br>" . "<b>Multiplex Run Analysis ID:</b> $mra_link<br>" . "<b>Pipeline:</b> $pipeline_link<br>" . "<b>Work Type:</b> $invoice_pipeline_name</br>";
    }

    return $info;
}

#####################
# Input: Invoiceable_Work_ID
# Output: A warning message if the funding is conflicted else nothing
#
#####################
sub funding_warning {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    ## Getting basic information about the invoiceable_work item
    my ($lib) = $dbc->Table_find( 'Invoiceable_Work IW, Plate', 'Plate.FK_Library__Name', "WHERE IW.Invoiceable_Work_ID in ($id) AND IW.FK_Plate__ID = Plate.Plate_ID" );
    my ( $iw_view_root, $iw_view_sub_path ) = alDente::Tools::get_standard_Path( -type => 'view', -group => 23, -structure => 'DATABASE' );
    my $link = $iw_view_root . '/' . $iw_view_sub_path;

    my $lib_link = &Link_To( $dbc->config('homelink'), "$lib", "&HomePage=Library&ID=$lib" );
    my $change_work_req_link
        = &Link_To( $dbc->config('homelink'), "Assign a funding to this Invoiceable_Work by linking plate to a Work_Request", "&cgi_application=alDente::View_App&rm=Display&File=$link\/general//Plate_Work_Request_Editor.yml&Generate+Results=1" );
    $change_work_req_link =~ s/Target_Department/\&Target_Department/;    #### <CONSTRUCTION> ##### Lili come fix this later, temporary hard code for interface testing
    ## Warning for when there is no Funding and having an option to change it
    ## Selects the Funding ID of Invoiceable_Work where the Invoiceable Work has a funding source
    my ($funding_info) = $dbc->Table_find_array(
        'Funding, Invoiceable_Work_Reference',
        [ 'Funding_Name', 'Funding_ID' ],
        "WHERE FKReferenced_Invoiceable_Work__ID = $id AND Invoiceable_Work_Reference.FKApplicable_Funding__ID = Funding_ID AND (Invoiceable_Work_Reference.Indexed is NULL OR Invoiceable_Work_Reference.Indexed = 0)"
    );
    my ( $funding, $funding_id ) = split ',', $funding_info;

    my ($plate_funding_info)
        = $dbc->Table_find_array( 'Invoiceable_Work,Plate,Work_Request, Funding', [ 'Funding_Name', 'Funding_ID' ], "WHERE FK_Plate__ID = Plate_ID AND Invoiceable_Work_ID = $id AND FK_Work_Request__ID = Work_Request_ID AND FK_Funding__ID = Funding_ID" );
    my ( $plate_funding, $plate_funding_id ) = split ',', $plate_funding_info;

    if ( !$funding || ( ( $plate_funding ne $funding ) && $plate_funding ) ) {
        my $funding_btn = $self->set_funding_btn( -dbc => $dbc, -library => $lib );

        my $funding_message .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Funding_Error' ) . $funding_btn . hidden( -name => 'ID', -value => $id, -force => 1 ) . end_form();
        if ( !$funding ) {
            print Message(
                "Warning: No Funding ID associated with this work item because multiple funding associated with library.<br>
                          Please specify which funding to use.<br><br>
                          *Note* Funding values have been taken from library $lib_link<br><br>                         
               			  $change_work_req_link"

            );
        }
        elsif ( ( $plate_funding ne $funding ) && ($plate_funding) ) {

            my $funding_link       = &Link_To( $dbc->config('homelink'), "$funding",       "&HomePage=Funding&ID=$funding_id" );
            my $plate_funding_link = &Link_To( $dbc->config('homelink'), "$plate_funding", "&HomePage=Funding&ID=$plate_funding_id" );

            print Message(
                "NOTE: FK_Funding__ID in Invoiceable_Work is being phased out for IWR. This message may be expected.
                Warning: Plate Funding and Work Funding not the same.<br>
                Two funding sources are set for one work item.<br><br>
                Plate_Funding: $plate_funding_link<br>
                Work Funding: $funding_link<br><br>
                Please change invoiceable work funding below...<br><br>
                *Note* Funding values have been taken from library $lib_link<br><br>
                $funding_message"
            );
        }
    }
    else {
        my $parent_iwr = &has_multiple_invoiceable_work_ref( -dbc => $dbc, -id => $id );

        if ($parent_iwr) {
            my @child_funding_id = $dbc->Table_find( 'Invoiceable_Work_Reference', "DISTINCT IFNULL(FKApplicable_Funding__ID, 'NULL')", "WHERE FKParent_Invoiceable_Work_Reference__ID = $parent_iwr ORDER BY Invoiceable_Work_Reference_ID" );
            my ($parent_funding) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FKApplicable_Funding__ID', "WHERE Invoiceable_Work_Reference_ID = $parent_iwr" );
            my $diff_funding;

            foreach my $child (@child_funding_id) {
                if ( $parent_funding != $child ) {
                    $diff_funding = 1;
                }
            }

            my @multiple_funding;

            my @parent_funding
                = $dbc->Table_find( 'Invoiceable_Work, Plate, Work_Request', 'FK_Funding__ID', "WHERE Invoiceable_Work.FK_Plate__ID = Plate_ID AND Plate.FK_Library__Name = Work_Request.FK_Library__Name AND Invoiceable_Work_ID = $id", -distinct => 1 );

            push @multiple_funding, @parent_funding;

            my $parent_funding_string = Cast_List( -list => \@parent_funding, -to => 'string' );

            my @children_funding = $dbc->Table_find_array(
                "Work_Request, Plate Parent, Plate Child, ReArray, ReArray_Request",
                ['FK_Funding__ID'],
                "WHERE Parent.FK_Library__Name = '$lib' AND ReArray_Request.FKTarget_Plate__ID = Parent.Plate_ID AND ReArray.FK_ReArray_Request__ID = ReArray_Request_ID AND ReArray.FKSource_Plate__ID = Child.Plate_ID AND Child.FK_Library__Name = Work_Request.FK_Library__Name AND FK_Funding__ID NOT IN ($parent_funding_string)",
                -distinct => 1
            );

            push @multiple_funding, @children_funding;

            if ( $diff_funding || ( ( scalar @multiple_funding ) > 1 ) ) {
                my $funding_btn = $self->set_funding_btn( -dbc => $dbc, -library => $lib );

                my $funding_message .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Funding_Error' ) . $funding_btn . hidden( -name => 'ID', -value => $id, -force => 1 ) . end_form();
                print Message(
                    "This Invoiceable Work item has children Invoiceable_Work_Reference items with multiple funding sources or whose funding does not match that of its parent.<br>
                        If the funding appears to be incorrect for any of the child items please use the button below to select which items to change the funding for.<br>
                            $funding_message"
                );
            }
        }
    }
    return;
}

##################################
# Trigger that updates the Invoiceable_Work billable status item once the run.billable field has been updated
# There is another trigger which updates billable status once invoiceable_work_reference.billable is updated
#
# Input: When -table = 'Run' then One Run_ID
# Input: When -table = 'Invoiceable_Work_Reference' could be a list of ids
# Output: whether syncing was a success or not. 1 = yes, null = no
##################################
sub invoice_billable_trigger {
##################################

    my $self            = shift;
    my %args            = &filter_input( \@_ );
    my $dbc             = $args{-dbc};
    my $id              = $args{-id};
    my $triggered_table = $args{-table};
    my $debug           = $args{-debug};
    my $result;

    $dbc->warning("In invoice_billable_trigger()\n") if $debug;
    Message("In invoice_billable_trigger()")         if $debug;
    Message("id = $id")                              if $debug;
    Message("triggered_table = $triggered_table")    if $debug;

    if ( !$id ) {
        return $result;
    }

    my $id_list = Cast_List( -list => $id, -to => 'string', -autoquote => 1 );

    if ( $triggered_table eq 'Run' ) {

        my ($billable) = $dbc->Table_find( 'Run', 'Run.Billable', "WHERE Run_ID IN ($id)" );
        $result = $self->sync_billable( -dbc => $dbc, -table => $triggered_table, -billable => $billable, -ids => $id, -debug => $debug );

    }
    elsif ( $triggered_table eq 'Invoiceable_Work_Reference' ) {

        my @billable = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference.Billable', "WHERE Invoiceable_Work_Reference_ID IN ($id_list)" );
        $result = $self->sync_billable( -dbc => $dbc, -table => $triggered_table, -billable => $billable[0], -ids => $id, -debug => $debug );

    }
    return $result;
}

##################################
# Trigger that updates the invoice related fields when FK_Invoice__ID has been updated
#
# Input: Invoiceable_Work_Reference(s) - ideally only the parent iwr records
# Output: number of records updated (should only be 1)
##################################
sub iwr_invoice_trigger {
##################################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $id    = $args{-id};
    my $debug = $args{-debug};

    $dbc->warning("In iwr_invoice_trigger()\n")      if $debug;
    Message("In iwr_invoice_trigger()")              if $debug;
    Message("Invoiceable_Work_Reference(s) = $id\n") if $debug;

    my @ids_list = @{$id};
    my $update;
    my $count = scalar(@ids_list);
    my $done  = 0;

    # update the invoice related fields
    foreach my $iwr_id (@ids_list) {

        my $invoiced = "No";
        my ($invoice_id) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FK_Invoice__ID', "WHERE Invoiceable_Work_Reference_ID = $iwr_id" );
        $invoiced   = "Yes"  if $invoice_id;
        $invoice_id = "NULL" if !$invoice_id;

        my $children_ref = $self->get_child_invoiceable_work_reference( -dbc => $dbc, -invoiceable_work_reference_ids => [$iwr_id] );
        my @children     = @{$children_ref};
        my $children_str = join ',', @children;

        Message("*** Invoiceable Work Reference Children: $children_str ***") if $debug;

        $update += $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['FK_Invoice__ID'], [$invoice_id], "WHERE Invoiceable_Work_Reference_ID IN ($children_str)", -no_triggers => 1 ) if $children_str;
        my @list_ids;
        push @list_ids, @children;
        push @list_ids, $iwr_id;
        my $ids_str = join ',', @list_ids;

        print HTML_Dump( \@list_ids ) if $debug;

        $update += $dbc->Table_update_array(
            'Invoiceable_Work_Reference', ['Invoice_Status'], ["Debit"],
            "WHERE Invoiceable_Work_Reference_ID IN ($ids_str) AND Invoice_Status != 'Credit' AND FK_Invoice__ID IS NOT NULL",
            -autoquote   => 1,
            -no_triggers => 1
        );
        $update += $dbc->Table_update_array(
            'Invoiceable_Work_Reference', ['Invoice_Status'], ["n/a"],
            "WHERE Invoiceable_Work_Reference_ID IN ($ids_str) AND FK_Invoice__ID IS NULL",
            -autoquote   => 1,
            -no_triggers => 1
        );
        $update += $dbc->Table_update_array(
            'Invoiceable_Work_Reference', ['Invoiceable_Work_Reference_Invoiced'], [$invoiced],
            "WHERE Invoiceable_Work_Reference_ID IN ($ids_str)",
            -autoquote   => 1,
            -no_triggers => 1
        );

        if ( $count > 1 ) {
            $done++;
            my $completion = int( 100 * ( $done / $count ) );
            print "Updating Invoice related fields for Invoiceable Work Reference records (@ids_list) and their children : $completion% done...\n" if $debug;
        }
        else {
            print "Updated Invoice related fields for Invoiceable Work Reference record (@ids_list) and its children\n" if $debug;
        }

    }

    return $update;
}

##########################
# The run.billable field may get phased out.
# Synchronizing Run.Billable and Invoiceable_Work_Reference.Billable
#
# please adjust the above script as follows:
# add a hash reference at the top of the script to keep track of the synchronized fields. (eg %Sync = {'Run.Billable' => 'sync_billable','Invoiceable_Work_Reference.Billable' => 'sync_billable', ....}
# The keys of the hash should represent ALL redundant synchronized fields. The values of the hash should represent the block executed to synchronized the specified field (there will typically be two distinct keys pointing to the same block as in this example)
# enable context specific call from the command line for a specific block.
# eg "check_redundancies.pl -field Run.Billable": This would only run the sync_billable method for example.
# enable record specific call from the command line for a specific record. (only applicable if a block/field is also specified)
# eg "check_redundancies.pl -field Invoiceable_Work_Reference.Billable -id 1234": This would run the synchronization only for the Billable block when the Invoiceable_Work_Reference_ID = 1234.
#
# Assumption: All Invoiceable_Work_Reference that belong to the same Invoiceable_Work will have the same billable status
#
#
#
#
#
# sample input: sync_billable( -dbc => $dbc, -table => 'Run', -billable => 'Yes', -ids => [133230, 1094, 401] )
##########################
sub sync_billable {
##########################
    my $self            = shift;
    my %args            = &filter_input( \@_ );
    my $dbc             = $args{-dbc};
    my $ids             = $args{-ids};            ## eg. -ids => 1 or '1,2' or [1, 2]  or ['str1', 'str2']
    my $triggered_table = $args{-table};
    my $billable_status = $args{-billable};
    my $debug           = $args{-debug};

    Message("In sync_billable()") if $debug;
    print HTML_Dump \%args        if $debug;

    require SDB::DB_Object;
    require alDente::Invoice;

    my $result;
    my $id_string;
    my @id_list;

    my @id_list = Cast_List( -list => $ids, -to => 'Array' );
    $id_string = join ',', @id_list;    ## $id_string would be '1,2,3...'

    my $set_fields    = [ 'Run.Billable', 'Invoiceable_Work_Reference.Billable' ];
    my $set_condition = "Invoiceable_Run.FK_Invoiceable_Work__ID = Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID AND Invoiceable_Run.FK_Run__ID = Run.Run_ID";
    my $set_add_table = "Invoiceable_Run";
    my $set_id;

    if ( $triggered_table eq 'Invoiceable_Work_Reference' ) {

        # Looks for all mismatched records (billable mismatch) that are from the same Invoiceable Work ID
        my (@iwr_ids) = $dbc->Table_find_array(
            'Invoiceable_Work_Reference AS parentIWR, Invoiceable_Work_Reference AS allIWR',
            ['allIWR.Invoiceable_Work_Reference_ID'],
            "WHERE parentIWR.Invoiceable_Work_Reference_ID IN ($id_string) AND parentIWR.FKReferenced_Invoiceable_Work__ID = allIWR.FKReferenced_Invoiceable_Work__ID AND allIWR.Billable <> '$billable_status'"
        );

        if (@iwr_ids) {
            my $iwr_ids_str = join ',', @iwr_ids;

            Message("Found IWR IDs: $iwr_ids_str") if $debug;

            sync_billable_email_helper( -dbc => $dbc, -iwr_id_string => $iwr_ids_str, -billable_status => $billable_status, -debug => $debug );

            $dbc->Table_update_array(
                "Invoiceable_Work_Reference",
                ['Billable'],
                [$billable_status],
                "WHERE Invoiceable_Work_Reference_ID in ($iwr_ids_str)",
                -autoquote => 1,
                -debug     => $debug
            );
        }
        else {

            sync_billable_email_helper( -dbc => $dbc, -iwr_id_string => $id_string, -billable_status => $billable_status, -debug => $debug );

        }

        #updating Run records that are mismatched in billable status
        my ($sync_run_id) = $dbc->Table_find( 'Invoiceable_Work_Reference, Invoiceable_Run, Run',
            'Run.Run_ID', "WHERE Invoiceable_Work_Reference_ID in ($id_string) AND FKReferenced_Invoiceable_Work__ID = FK_Invoiceable_Work__ID AND FK_Run__ID = Run_ID AND Run.Billable <> Invoiceable_Work_Reference.Billable" );

        if ($sync_run_id) {
            Message("synced run ids: $sync_run_id") if $debug;
            my $ok = $dbc->Table_update_array(
                "Run",
                ['Billable'],
                [$billable_status],
                "WHERE Run.Run_ID IN ($sync_run_id)",
                -autoquote => 1,
                -debug     => $debug
            );
            unless ($ok) {    ## Syncing unsuccessful
                return $result;
            }
        }
        $result = 1;          #successful syncing
    }
    elsif ( $triggered_table eq 'Run' ) {

        my (@iwr_ids) = $dbc->Table_find_array(
            'Invoiceable_Work_Reference, Invoiceable_Run, Run',
            ['Invoiceable_Work_Reference_ID'],
            "WHERE Run_ID in ($id_string) AND FKReferenced_Invoiceable_Work__ID = FK_Invoiceable_Work__ID AND FK_Run__ID = Run_ID AND Run.Billable <> Invoiceable_Work_Reference.Billable"
        );

        if (@iwr_ids) {
            my $iwr_ids_str = join ',', @iwr_ids;

            Message("Found IWR IDs: $iwr_ids_str") if $debug;

            sync_billable_email_helper( -dbc => $dbc, -iwr_id_string => $iwr_ids_str, -billable_status => $billable_status, -debug => $debug );

            my $ok = $dbc->Table_update_array( "Invoiceable_Work_Reference", ['Billable'], [$billable_status], "WHERE Invoiceable_Work_Reference_ID in ($iwr_ids_str)", -autoquote => 1 );
            unless ($ok) {    ## Syncing unsuccessful
                return $result;
            }
        }
        $result = 1           #sucessful syncing
    }

    return $result;
}

##########################
##########################
#
# May need to simplify code...
#
# check invoiceable_work_reference or run's new and old billable status
# send email notification if billable status(from Change_History table) changed and is invoiced
##########################
sub sync_billable_email_helper {
##########################
    my %args            = &filter_input( \@_ );
    my $dbc             = $args{-dbc};
    my $iwr_id_string   = $args{-iwr_id_string};
    my $run_id_string   = $args{-run_id_string};
    my $billable_status = $args{-billable_status};
    my $debug           = $args{-debug};
    my @change_history;

    $dbc->warning("In sync_billable_email_helper()\n") if $debug;
    Message("In sync_billable_email_helper()")         if $debug;
    print HTML_Dump \%args                             if $debug;

    ## if input is run_id
    if ($run_id_string) {

        print message("Email Helper Run ID: $run_id_string") if $debug;

        my $condition = "Record_ID = Run_ID and FK_DBField__ID = 2845 AND Record_ID IN ($run_id_string) AND Modified_Date > DATE_SUB(NOW(), INTERVAL 1 MINUTE) ORDER BY Modified_Date DESC LIMIT 1";

        my @change_history = $dbc->Table_find_array( 'Change_History, Run', [ 'Run_ID', 'Old_Value', 'New_Value' ], "WHERE $condition" );
        my @changed_run_id;

        foreach my $run (@change_history) {
            my ( $each_run_id, $old_value, $new_value ) = split ',', $run;

            if ( $old_value ne $new_value ) {    ## given run_id -> find all invoiced iwr_id
                my @invoiced_iwr_ids = $dbc->Table_find_array(
                    'Invoiceable_Work_Reference, Invoiceable_Work, Invoiceable_Run, Run',
                    [ 'Invoiceable_Work_Reference_ID', 'Invoiceable_Work_Reference_Invoiced' ],
                    "WHERE FKReferenced_Invoiceable_Work__ID = Invoiceable_Work_ID AND FK_Invoiceable_Work__ID = Invoiceable_Work_ID AND FK_Run__ID = Run_ID AND Invoiceable_Work_Reference_Invoiced = 'Yes' AND Run_ID = $each_run_id"
                );

                if (@invoiced_iwr_ids) {
                    push @changed_run_id, $each_run_id;
                }
            }
        }
        Message("changed_run_id = @changed_run_id") if $debug;

        foreach my $changed_run_id (@changed_run_id) {
            my ($changed_iw_id) = $dbc->Table_find( 'Invoiceable_Run', 'FK_Invoiceable_Work__ID', "WHERE FK_Run__ID = $changed_run_id" );
            my @comments = $dbc->Table_find_array( 'Invoiceable_Work', ['Invoiceable_Work_Comments'], "WHERE Invoiceable_Work_ID = $changed_iw_id" );

            Message("Sending notification email through sync_billable_email_helper()...") if $debug;
            &billable_status_change_notification( $dbc, -iw_ids => $changed_iw_id, -billable_status => $billable_status, -billable_comments => $comments[0] );
        }
    }
    ## if input is invoiceable_work_reference_id
    elsif ($iwr_id_string) {

        print Message("Billable Email Helper IWR: $iwr_id_string") if $debug;

        my @iwr_ids = Cast_List( -list => $iwr_id_string, -to => 'Array' );
        my @changed_iwr_id;

        foreach my $iwr_id (@iwr_ids) {
            my $condition = "Record_ID = Invoiceable_Work_Reference_ID and FK_DBField__ID = 4619 AND Record_ID IN ($iwr_id) AND Modified_Date > DATE_SUB(NOW(), INTERVAL 2 MINUTE) ORDER BY Modified_Date DESC LIMIT 1";
            my @temp_change_history = $dbc->Table_find_array( 'Change_History, Invoiceable_Work_Reference', [ 'Invoiceable_Work_Reference_ID', 'Invoiceable_Work_Reference_Invoiced', 'Old_Value', 'New_Value' ], "WHERE $condition" );
            push @change_history, @temp_change_history;
        }

        foreach my $iwr (@change_history) {
            my ( $each_iwr_id, $invoiced, $old_value, $new_value ) = split ',', $iwr;

            if ( ( $old_value ne $new_value ) && ( $invoiced eq 'Yes' ) ) {
                push @changed_iwr_id, $each_iwr_id;
            }
        }
        if (@changed_iwr_id) {
            my $changed_iwr_id_string = join ',', @changed_iwr_id;
            my @changed_iw_id = $dbc->Table_find_array( 'Invoiceable_Work_Reference', ['FKReferenced_Invoiceable_Work__ID'], "WHERE Invoiceable_Work_Reference_ID IN ($changed_iwr_id_string) GROUP BY FKReferenced_Invoiceable_Work__ID" );

            Message("changed_iwr_id = @changed_iwr_id") if $debug;

            my $iw_string = join ',', @changed_iw_id;
            ## filter out the iw_ids that have the same library names
            my (@unique_iw_id) = $dbc->Table_find_array( 'Invoiceable_Work, Plate, Library', ['Invoiceable_Work_ID'], "WHERE Invoiceable_Work_ID IN ($iw_string) AND FK_Plate__ID = Plate_ID AND FK_Library__Name = Library_Name GROUP BY Library_Name;" );

            foreach my $changed_iw_id (@unique_iw_id) {
                my @comments = $dbc->Table_find_array( 'Invoiceable_Work', ['Invoiceable_Work_Comments'], "WHERE Invoiceable_Work_ID = $changed_iw_id" );

                Message("Sending notification email through sync_billable_email_helper()...") if $debug;
                &billable_status_change_notification( $dbc, -iw_ids => $changed_iw_id, -billable_status => $billable_status, -billable_comments => $comments[0] );
            }
        }
    }
    return 1;
}

################################
# This is used to replace the old method "get_child_invoiceable_work" in alDente::Invoice.pm
# returns a string of invoiceable_work_reference ids
################################
sub get_child_invoiceable_work_reference {
################################

    my $self                           = shift;
    my %args                           = &filter_input( \@_ );
    my $dbc                            = $args{-dbc};
    my $invoiceable_work_reference_ids = $args{-invoiceable_work_reference_ids};

    my @invoiceable_work_reference_id = @{$invoiceable_work_reference_ids};
    my $iwr_ids;
    my @child_iwr_id;

    if (@invoiceable_work_reference_id) {
        $iwr_ids = join ',', @invoiceable_work_reference_id;
        @child_iwr_id = $dbc->Table_find_array( 'Invoiceable_Work_Reference', ['Invoiceable_Work_Reference_ID'], "WHERE FKParent_Invoiceable_Work_Reference__ID IN ($iwr_ids)", -autoquote => 1 );
    }

    if (@child_iwr_id) {
        my @child_child_iwr_id = @{ $self->get_child_invoiceable_work_reference( -dbc => $dbc, -invoiceable_work_reference_ids => \@child_iwr_id ) };
        push @child_iwr_id, @child_child_iwr_id;
        return \@child_iwr_id;
    }
    else {

        return [];
    }
}

######################
# Appends comments to Invoiceable_Work_Item_Comments field
#
# <snip>
#	my $ok = alDente::Invoiceable_Work::append_invoiceable_work_comment( -dbc => $dbc, -invoiceable_work_id => \@ids, -iw_comments => $iw_comments );
# <snip>
#
# Return:
#	Scalar, Number of Invoiceable_Work records being updated
######################
#########################
sub append_invoiceable_work_comment {
#########################
    my %args                = filter_input( \@_, -args => 'dbc,invoiceable_work_id,iw_comment' );
    my $dbc                 = $args{-dbc};
    my $invoiceable_work_id = $args{-invoiceable_work_id};
    my $quiet               = $args{-quiet};
    my $comments            = $args{-iw_comments};

    my $invoiceable_work_ids = Cast_List( -list => $invoiceable_work_id, -to => 'String' );

    unless ( $invoiceable_work_ids =~ /[1-9]/ ) {
        Message("Unable to find works ($invoiceable_work_ids)") unless ($quiet);
    }

    if ( !$comments ) {
        Message("No comments were added") unless ($quiet);
        return 0;
    }

    my $time = date_time();

    # add comment only if not indexed, and add line break if comment exists
    my $formatted_comment = "[$time]-";

    $formatted_comment .= "$comments";

    my $ok = $dbc->Table_update_array(
        "Invoiceable_Work",
        ['Invoiceable_Work_Item_Comments'],
        [$formatted_comment],
        "WHERE Invoiceable_Work.Invoiceable_Work_ID IN ($invoiceable_work_ids)",
        -append_only_fields => ['Invoiceable_Work_Item_Comments'],
        -autoquote          => 1
    );
    if ($ok) {
        print Message ("Work Item Comment '$comments' was appended to the following Invoiceable Work items: @$invoiceable_work_id");
    }

    return $ok;
}

##############################
# Checks if a given Invoiceable_Work_ID has multiple Invoiceable_Work_Reference
# items associated to it. If yes, one of the IWR items is a parent and the rest
# are it's children.
#
# Input: Invoiceable_Work_ID
# Output: The Parent Invoiceable_Work_Reference_ID or NULL
##############################
sub has_multiple_invoiceable_work_ref {
##############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc, id' );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $id   = $args{-id};

    my ($parent_iwr) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE FKReferenced_Invoiceable_Work__ID = $id AND FKParent_Invoiceable_Work_Reference__ID IS NULL" );

    my @iwr_ids = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE FKParent_Invoiceable_Work_Reference__ID = $parent_iwr" );

    if ( ( scalar @iwr_ids ) > 0 ) {
        return $parent_iwr;
    }
    else {
        return 0;
    }
}

##################################
# Trigger that send email notification to Project team once the IWR.FKApplicable_Funding__ID field has been changed
##################################
sub iwr_change_funding_trigger {
##################################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $id    = $args{-id};             # Invoiceable_Work_Reference_ID
    my $debug = $args{-debug};

    my @iwr_ids = @{$id};
    my $iwr_string = join ',', @iwr_ids;

    require alDente::Invoice;
    Message("Invoiceable_Work_Reference_IDs: $iwr_string") if $debug;

    my @iw_ids = $dbc->Table_find(
        'Invoiceable_Work_Reference', 'FKReferenced_Invoiceable_Work__ID',
        "WHERE Invoiceable_Work_Reference_ID IN ($iwr_string)",
        -distinct => 1,
        -debug    => $debug
    );

    my @affected_iw;
    my @old_funding;
    my @new_funding;
    foreach my $iw (@iw_ids) {
        my @iwr = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE FKReferenced_Invoiceable_Work__ID = $iw" );
        my $iwr_id_string = Cast_List( -list => \@iwr, -to => 'string' );
        if ($iwr_id_string) {
            my ($change_history)
                = $dbc->Table_find_array( 'Change_History', [ 'Old_Value', 'New_Value' ], "WHERE FK_DBField__ID = 4849 AND Record_ID IN ($iwr_id_string) AND Modified_Date > DATE_SUB(NOW(), INTERVAL 2 MINUTE) ORDER BY Modified_Date DESC LIMIT 1" );
            my ( $old_funding, $new_funding ) = split ',', $change_history;
            Message("Invoiceable Work ID: $iw, Old Funding ID: $old_funding, New Funding ID: $new_funding") if $debug;
            if ( $old_funding ne $new_funding && $old_funding ) {
                push @affected_iw, $iw;
                push @old_funding, $old_funding;
                push @new_funding, $new_funding;
            }
        }
    }

    if (@affected_iw) {
        Message("Sending notification email through iwr_change_funding_trigger()...") if $debug;
        &iw_funding_change_notification( $dbc, -iw_ids => \@affected_iw, -new_funding => \@new_funding, -old_funding => \@old_funding );
    }

    return;
}

##################################
# Input: Invoiceable_Work ids (should only pass in those with changed funding)
# Notification for funding changes - Invoiceable_Work records, and appends message to bulk email
##################################
sub iw_funding_change_notification {
##################################
    my %args                = &filter_input( \@_, -args => 'dbc,iw_ids,new_funding,old_funding', -mandatory => 'dbc,iw_ids,new_funding,old_funding' );
    my $dbc                 = $args{-dbc};
    my $iw_ids              = $args{-iw_ids};
    my @new_funding_id_list = @{ $args{-new_funding} };
    my @old_funding_id_list = @{ $args{-old_funding} };
    my $debug               = $args{-debug};

    $dbc->warning("In iw_funding_change_notification()\n") if $debug;
    Message("In iw_funding_change_notification()")         if $debug;

    ## Grouping invoiceable work items changed by library
    ## Each key contains a 2D array where each element of the first array (items grouped by iw) contains another array containing the iw_id, old_funding, new_funding
    my %affected_libs;
    my $i = 0;
    foreach my $iw (@$iw_ids) {
        my ($library) = $dbc->Table_find(
            'Invoiceable_Work IW LEFT JOIN Plate ON Plate_ID = IW.FK_Plate__ID LEFT JOIN Run_Analysis RA ON RA.Run_Analysis_ID = IW.FK_Run_Analysis__ID
                                           LEFT JOIN Sample RA_Sample ON RA_Sample.Sample_ID = RA.FK_Sample__ID
                                           LEFT JOIN Multiplex_Run_Analysis MRA ON MRA.Multiplex_Run_Analysis_ID = IW.FK_Multiplex_Run_Analysis__ID
                                           LEFT JOIN Sample MRA_Sample ON MRA_Sample.Sample_ID = MRA.FK_Sample__ID
                                           LEFT JOIN Library ON Library_Name = COALESCE(Plate.FK_Library__Name, MRA_Sample.FK_Library__Name, RA_Sample.FK_Library__Name)',
            'Library_Name',
            "WHERE Invoiceable_Work_ID = $iw",
            -distinct => 1,
        );
        $affected_libs{$library}{$iw} = "$old_funding_id_list[$i], $new_funding_id_list[$i]";
        $i++;
    }

    my ( $iw_view_root, $iw_view_sub_path ) = alDente::Tools::get_standard_Path( -type => 'view', -group => 43, -structure => 'DATABASE' );
    my $iw_view_filepath = $iw_view_root . $iw_view_sub_path . 'general/Invoiced_Work.yml';
    my $changed_invoiceable_items;
    my $homelink = $dbc->homelink( -clear => 'CGISESSID' );
    my $iw_id_string = Cast_List( -list => $iw_ids, -to => 'String' );
    if ( -e $iw_view_filepath ) {
        $changed_invoiceable_items = &Link_To( $homelink, "Changed invoiceable items", "&cgi_application=alDente::View_App&rm=Display&File=$iw_view_filepath&Invoiceable_Work_ID=$iw_id_string&Generate+Results=1" );
    }

    ## check change history table eg. in Invoiceable_Work.pm file see example
    # check if value changes
    my $subject_str = "Invoiceable Work Funding Change Notification";

    my $msg .= "Click here to view changed items: $changed_invoiceable_items </p>";

    foreach my $lib ( keys %affected_libs ) {
        my @affected_iws;
        my @old_fundings;
        my @new_fundings;
        foreach my $info ( keys %{$affected_libs{$lib}} ) {
            push @affected_iws, $info;
            my ( $old_funding, $new_funding ) = split ',', $affected_libs{$lib}{$info};
            my $old_funding_name = '';
            my $new_funding_name = '';
            if ($old_funding) { ($old_funding_name) = $dbc->Table_find( 'Funding', 'Funding_Name', "WHERE Funding_ID = $old_funding", -distinct => 1 ) }
            if ($new_funding) { ($new_funding_name) = $dbc->Table_find( 'Funding', 'Funding_Name', "WHERE Funding_ID = $new_funding", -distinct => 1 ) }
            push @old_fundings, $old_funding_name;
            push @new_fundings, $new_funding_name;
        }

        my $affected_iws_string = Cast_List( -list => \@affected_iws, -to => 'string' );
        my $old_funding_string  = Cast_List( -list => \@old_fundings, -to => 'string' );
        my $new_funding_string  = Cast_List( -list => \@new_fundings, -to => 'string' );

        $msg .= "<p ></p>The funding of the following invoiceable work records for library <strong>$lib</strong> have been changed:<br>";
        $msg .= "<strong>Invoiceable_Work ID:</strong>$affected_iws_string<br>";
        $msg .= "<strong>Old Invoiceable Work Funding:</strong>$old_funding_string<br>";
        $msg .= "<strong>New Invoiceable Work Funding:</strong>$new_funding_string<br><br>";
        my @iw_summary_fields = ( 'work_id', 'library', 'library_strategy', 'protocol', 'work_type', 'work_date', 'pla', 'tra', 'run_id', 'run_type', 'invoice', 'billable', 'billable_comments', 'funding', 'qc_status', 'qc_status_comment' );
        my $changed_iw_info = alDente::Invoice_Views::get_invoiceable_work_summary( -dbc => $dbc, -iw_ids => \@affected_iws, -field_list => \@iw_summary_fields, -no_title => 1 );
        $changed_iw_info = HTML_Table::remove_credential( -string => $changed_iw_info, -credentials => 'CGISESSID' );
        $msg .= "<strong>Changed Invoiceable Work Record:</strong><br>";
        $msg .= $changed_iw_info;
        my $lib_iw_summary = alDente::Invoice_Views::get_invoiceable_work_summary( -dbc => $dbc, -library_names => [$lib], -field_list => \@iw_summary_fields, -no_title => 1 );
        $lib_iw_summary = HTML_Table::remove_credential( -string => $lib_iw_summary, -credentials => 'CGISESSID' );
        $msg .= "<strong>List of Invoiceable Works for Library $lib\:</strong><br>";
        $msg .= $lib_iw_summary;
    }

    require alDente::Subscription;
    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => "Work Funding Change",
        -from         => 'aldente@bcgsc.ca',
        -subject      => "$subject_str - (from Invoice)",
        -body         => $msg,
        -content_type => 'html'
    );

    return $ok;
}

#
# Updates the Invoiceable_Work_Reference table so that that all tuples pont to the parent Invoiceable_Work.
# This is meant to handle multiple pooling
# Usage: $Invoiceable_Work->backfill_invoiceable_work_reference()
#
#############################
sub backfill_invoiceable_work_reference {
############################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc = $self->{dbc};

    my @id_list = ();

    @id_list = $dbc->Table_find_array( "Invoiceable_Work", ['Invoiceable_Work_ID'], "WHERE FKParent_Invoiceable_Work__ID IS NULL" );
    my $count = scalar(@id_list);

    print Message("There are $count records to update");

    foreach my $parent (@id_list) {
        my @array = ($parent);
        my @children = @{ $self->get_child_invoiceable_work( -dbc => $dbc, -invoiceable_work_ids => \@array ) };
        if (@children) {
            my $child_list = join( ', ', @children );
            Message("Children of $parent are $child_list");
            my $updated_child = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['FKReferenced_Invoiceable_Work__ID'], [$parent], "WHERE Invoiceable_Work_Reference_ID IN ($child_list)", -autoquote => 1 );
            Message("$updated_child were updated");
        }
        else {
            Message("ID $parent has no children");
        }
    }

    return;
}

#
# Currently used only by the Invoiced_Work view. Using a method to generate the results for the view makes the query much faster
#
# Input: Invoiceable_Work_ID
# Output: Change_History comments for the runs.
#
################################
sub get_change_history_comments {
################################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc,iw_list', -mandatory => 'dbc,iw_list' );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $iw_list = $args{-iw_list};

    my @iw_list;
    if ($iw_list) {
        @iw_list = @$iw_list;
    }
    else {
        Message('Required mandatory input parameter not recognized.');
        return;
    }

    my @results;
    foreach my $iw (@iw_list) {
        my ($comment)
            = $dbc->Table_find( 'Invoiceable_Run IR, Change_History CH', 'GROUP_CONCAT(DISTINCT CH.Comment)', "WHERE IR.FK_Invoiceable_Work__ID = $iw AND CH.Record_ID = CAST(IR.FK_Run__ID AS CHAR(40)) AND CH.FK_DBField__ID = 3540", -distinct => 1 );

        push @results, $comment;
    }

    return \@results;
}

##################################
# Input: Invoiceable_Work ids (should only pass in those with changed billable status)
# Notification for billable status changes on Invoiced- Invoiceable_Work records
#
#	Checks if billable work is Invoiced...if it is, appends message to bulk email
##################################
sub billable_status_change_notification {
##################################
    my %args              = &filter_input( \@_, -args => 'dbc,iw_ids,billable_status,billable_comments', -mandatory => 'dbc,iw_ids,billable_status' );
    my $dbc               = $args{-dbc};
    my $iw_ids            = $args{-iw_ids};
    my $billable_status   = $args{-billable_status};
    my $billable_comments = $args{-billable_comments};

    my @iw_summary_fields = ( 'work_id', 'library', 'library_strategy', 'protocol', 'work_type', 'work_date', 'pla', 'tra', 'run_id', 'run_type', 'invoice', 'billable', 'billable_comments', 'qc_status', 'qc_status_comment' );
    my $changed_iw_info = alDente::Invoice_Views::get_invoiceable_work_summary( -dbc => $dbc, -iw_ids => $iw_ids, -field_list => \@iw_summary_fields );

    # remove session ID so that it won't be sent out in notification email
    $changed_iw_info = HTML_Table::remove_credential( -string => $changed_iw_info, -credentials => 'CGISESSID' );

    my $iw_id_string = Cast_List( -list => $iw_ids, -to => 'String' );

    my ( $iw_view_root, $iw_view_sub_path ) = alDente::Tools::get_standard_Path( -type => 'view', -group => 43, -structure => 'DATABASE' );
    my $iw_view_filepath = $iw_view_root . $iw_view_sub_path . 'general/Invoiced_Work.yml';

    my $changed_invoiceable_items;
    my $homelink = $dbc->homelink( -clear => 'CGISESSID' );

    if ( -e $iw_view_filepath ) {
        $changed_invoiceable_items = &Link_To( $homelink, "Changed invoiceable items", "&cgi_application=alDente::View_App&rm=Display&File=$iw_view_filepath&Invoiceable_Work_ID=$iw_id_string&Generate+Results=1" );
    }

    my $subject_str = "Billable status change notification";

    my $msg = "<p ></p>The billable status of the following invoiceable work records (Invoiced) has been changed:<br />";
    $msg .= "<strong>Invoiceable_Work ID:</strong> $iw_id_string<br />";
    $msg .= "<strong>Billable status:</strong> $billable_status <br />";

    if ($billable_comments) {
        $msg .= "<strong>Reason for change:</strong> $billable_comments <br />";
    }

    $msg .= "Click here to view changed items: $changed_invoiceable_items </p>";
    $msg .= "$changed_iw_info";

    require alDente::Subscription;
    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => "Work Billable Status Change",
        -from         => 'aldente@bcgsc.ca',
        -subject      => "$subject_str - (from Invoice)",
        -body         => $msg,
        -content_type => 'html'
    );

    return $ok;
}

#
# Wrapper to enable regeneration of previous work that is newly defined as billable.
# Usage: $Invoiceable_Work->backfill_invoiceable_work(-work=>$work);  ## $work is the Invoiceable_Protocol_Type
#
# This method backfills a variety of items
# 1) Given a prep name in the Invoice_Protocol table backfills all of these
# 2) given a specific run name in the invoice_run_type, backfills all the runs of that type
# 3) Given a project, backfills all the runs for that project
#
#############################
sub backfill_invoiceable_work {
############################
    my $self = shift;
    my %args = filter_input( \@_, -mandatory => 'prep|project|run|project_status|analysis' );

    my $prep             = $args{-prep};                ## Invoice protocol type to backfill
    my $run              = $args{-run};                 ## Invoice_Run_Type to backfill
    my $analysis         = $args{-analysis};            ## Invoice_Pipeline_Name to backfill
    my $project          = $args{-project};             ## Project_ID to backfill
    my $work             = $args{-work};                ## Given the Invoice_Protocol_Name, helps refine the search for prep
    my $project_status   = $args{-project_status};      ## Backfills all projects that are in a given status. The three possible inputs are 'Active', 'Inactive', 'Completed'
    my $include_inactive = $args{-include_inactive};    ## Backfills invoiceable protocols that are considered inactive in addition to the ones that are active

    my $dbc = $self->{dbc};

    my $added = 0;

    ## Backfill specified work type ##
    if ($prep) {
        my $condition .= "Invoice_Protocol_Type = '$prep' ";
        if ($work) { $condition .= " AND Invoice_Protocol_Name = '$work'"; }

        unless ($include_inactive) { $condition .= " AND Invoice_Protocol_Status = 'Active'"; }

        my @invoice_protocol = $dbc->Table_find_array( "Invoice_Protocol", [ 'Invoice_Protocol_ID', 'FK_Lab_Protocol__ID', 'Invoice_Protocol_Name', 'Tracked_Prep_Name' ], "WHERE $condition AND FK_Lab_Protocol__ID > 0" );

        foreach my $iw (@invoice_protocol) {
            my ( $ip_id, $protocol_id, $name, $tracked_prep_name ) = split ',', $iw;
            my ($protocol_name) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_Name', "WHERE Lab_Protocol_ID = $protocol_id" );

            ## get all prep ids where indicated protocol matched the Tracked_Prep_Name.
            my @preps = $dbc->Table_find( 'Prep,Lab_Protocol', 'Prep_ID', "WHERE FK_Lab_Protocol__ID=Lab_Protocol_ID AND Lab_Protocol_ID = $protocol_id AND Prep_Name = '$tracked_prep_name'" );
            Message( "Found " . int(@preps) . " $name Preps to backfill for $name ($protocol_name\: $ip_id)" );

            foreach my $prep_id (@preps) {
                $added += $self->record_invoiceable_prep( -prep_id => $prep_id, -ip_id => $ip_id );
            }
            Message("Backfilled $added $work ($protocol_name) records.. ");
        }
    }

    ## Backfill invoiceable runs for a specific type of run
    if ($run) {
        my $condition = " Run_Type = '$run'";

        ##Get all the run ids where indicated protocol match the tracked run number
        my @runs = $dbc->Table_find( 'Run', 'Run_ID', "WHERE $condition" );
        Message( "Found " . int(@runs) . " Runs to backfill for Project $project..." );

        foreach my $run_id (@runs) {
            $added += $self->add_invoiceable_run_info( -run_id => $run_id );
        }
        Message("Backfilled $added Run records.. ");
    }

    ## Backfill Invoiceable Runs for Specific Project ##
    ## only perform for one project at a time as required... ##
    ## Requires Project_ID as input ##
    if ($project) {

        my $condition = "FK_Project__ID = $project";

        ### First backfill the prep for the project
        my @prep = $dbc->Table_find(
            'Prep,Plate_Prep,Plate, Library, Invoice_Protocol',
            'Prep_ID',
            "WHERE Invoice_Protocol.FK_Lab_Protocol__ID = Prep.FK_Lab_Protocol__ID AND Prep.Prep_ID = Plate_Prep.FK_Prep__ID AND Plate_Prep.FK_Plate__ID = Plate.Plate_ID AND Plate.FK_Library__Name = Library.Library_Name AND $condition",
            -distinct => 1
        );

        Message( "Found " . int(@prep) . " Prep to backfill for Project $project..." );

        my $added_prep = 0;

        foreach my $prep_id (@prep) {
            $added_prep += $self->add_invoiceable_prep_info( -prep_id => $prep_id, -backfill => 1 );

        }
        Message("Backfilled $added_prep Prep records.. ");

        ## Now backfill in the run information
        my @runs = $dbc->Table_find( 'Run,Plate,Library', 'Run_ID', "WHERE Run.FK_Plate__ID=Plate.Plate_ID AND Plate.FK_Library__Name = Library_Name AND $condition", -distinct => 1 );

        Message( "Found " . int(@runs) . " Runs to backfill for Project $project..." );

        foreach my $run_id (@runs) {
            $added += $self->add_invoiceable_run_info( -run_id => $run_id, -backfill => 1 );
        }
        Message("Backfilled $added Run records.. ");
    }

    ## a function that calls itself. Backfills work done on projects with a current status.
    if ($project_status) {

        my @project = $dbc->Table_find( 'Project', 'Project_ID', "WHERE Project_Status = '$project_status'" );

        foreach my $project_id (@project) {
            $added += $self->backfill_invoiceable_work( -project => $project_id );
        }
        Message("Backfilled $added invoiceable work line items..");
    }

    ## For analyses, only need to create Invoiceable_Work record. SQL Triggers will take care of creating Invoiceable_Work_Reference and Invoiceable_Run_Analysis records.
    if ($analysis) {
        my @ra_ids
            = $dbc->Table_find( 'Run_Analysis, Invoice_Pipeline', 'Run_Analysis_ID', "WHERE FKAnalysis_Pipeline__ID = FK_Pipeline__ID AND Invoice_Pipeline_Name = '$analysis' AND Run_Analysis_Finished IS NOT NULL AND Run_Analysis_Status = 'Analyzed'" );

        foreach my $ra (@ra_ids) {
            my @multiplex_ids = $dbc->Table_find( 'Multiplex_Run_Analysis', 'Multiplex_Run_Analysis_ID', "WHERE FK_Run_Analysis__ID = $ra" );
            my ($analysis_finished) = $dbc->Table_find( 'Run_Analysis', 'Run_Analysis_Finished', "WHERE Run_Analysis_ID = $ra" );

            if (@multiplex_ids) {
                foreach my $mra (@multiplex_ids) {
                    $dbc->Table_append_array( 'Invoiceable_Work', [ 'Invoiceable_Work_Type', 'Invoiceable_Work_DateTime', 'FK_Run_Analysis__ID', 'FK_Multiplex_Run_Analysis__ID' ], [ 'Analysis', $analysis_finished, $ra, $mra ], -autoquote => 1 );
                    $added++;
                }
            }
            else {
                $dbc->Table_append_array( 'Invoiceable_Work', [ 'Invoiceable_Work_Type', 'Invoiceable_Work_DateTime', 'FK_Run_Analysis__ID' ], [ 'Analysis', $analysis_finished, $ra ], -autoquote => 1 );
                $added++;
            }
        }
        Message("Backfilled $added invoiceable run analysis records.. ");
    }

    return $added;

}

# Input: Prep_ID, dbc
# Output: Added record else 0
# On insert into the Prep table, a trigger will call upon this method
# This method should perform a check to see whether the Prep is a invoiceable prep and if the prep is complete
# If so, it should call a method which will populate the invoiceable prep table with it's respective information
################################
sub add_invoiceable_prep_info {
################################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'dbc, prep_id' );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $prep_id   = $args{-prep_id};
    my $backfill  = $args{-backfill};
    my $test_flag = $args{-test_flag};
    my $added     = 0;

    my @invoiceable_prep = $dbc->Table_find_array(
        'Prep Pr, Lab_Protocol LP, Invoice_Protocol IP',
        [ 'IP.Invoice_Protocol_ID', 'IP.Invoice_Protocol_Status' ],
        "WHERE Pr.FK_Lab_Protocol__ID = LP.Lab_Protocol_ID AND LP.Lab_Protocol_ID = IP.FK_Lab_Protocol__ID AND Pr.Prep_Name = IP.Tracked_Prep_Name AND Pr.Prep_ID = $prep_id"
    );

    foreach my $ip (@invoiceable_prep) {
        my ( $ip_id, $status ) = split ',', $ip;

        if ( $status eq 'Active' or $backfill ) {

            #if prep is invoiceable (Prep is complete, protocol is in invoice_protocol and protocol is currently active)
            $added = $self->record_invoiceable_prep( -prep_id => $prep_id, -ip_id => $ip_id, -test_flag => $test_flag );
        }
    }

    return $added;
}

#
# Record invoiceable prep given the Prep_ID and Invoice_Protocol_ID
#
#
# Return: number of records added (should be number of PLAs in the Prep)
############################
sub record_invoiceable_prep {
############################
    my $self        = shift;
    my %args        = filter_input( \@_, -mandatory => 'prep_id, ip_id' );
    my $prep_id     = $args{-prep_id};
    my $ip_id       = $args{-ip_id};
    my $debug       = $args{-debug};
    my $indexed_src = $args{-indexed_src};
    my $indexed     = $args{-indexed};
    my $billable    = $args{-billable} || 'Yes';
    my $test_flag   = $args{-test_flag};                                     # used for testing
    my $comments    = $args{-comments} || '';

    my $dbc   = $self->{dbc};
    my $added = 0;

    my $invoiceable_work_id     = '';
    my $invoiceable_work_ref_id = '';
    my $invoiceable_prep_id     = '';
    my $indirect                = 0;
    my $src_id                  = '';
    my $total_iwr               = '';

    my ($recorded) = $dbc->Table_find( 'Prep Pr,Invoiceable_Prep IP, Invoiceable_Work IW', 'IW.Invoiceable_Work_ID', "WHERE IP.FK_Prep__ID=Pr.Prep_ID AND IW.Invoiceable_Work_ID = IP.FK_Invoiceable_Work__ID AND Prep_ID = $prep_id" );

    if ($recorded) {
        if ($debug) { $dbc->warning("Prep $prep_id <- already recorded (skipping)"); }
    }
    else {
        ## Getting IW information ##
        my @info = $dbc->Table_find_array(
            '(Plate, Plate_Prep, Prep) LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID=Plate_ID',
            [ 'Plate.Plate_ID', 'FK_Tray__ID', 'FK_Prep__ID', 'Prep.Prep_DateTime' ],
            "WHERE Plate_Prep.FK_Plate__ID = Plate.Plate_ID
            AND Prep.Prep_ID=Plate_Prep.FK_Prep__ID
            AND Prep_ID = $prep_id",
            -distinct => 1
        );

        if ( int(@info) == 0 ) {
            if ($debug) {
                Message("Warning: Problem retrieving information ( Prep_ID = $prep_id )");
            }
        }

        require alDente::Funding;
        my %plate_funding = %{ alDente::Funding::determine_plate_funding( -dbc => $dbc, -prep_ids => [$prep_id] ) };

        foreach my $initial_info (@info) {

            #get initial info to record Invoiceable_Work
            my ( $pla, $tra, $prep, $prep_datetime ) = split ',', $initial_info;

            # This is updating the Invoiceable_Work table
            $invoiceable_work_id = $dbc->Table_append_array(
                'Invoiceable_Work',
                [ 'Invoiceable_Work_ID', 'FK_Plate__ID', 'FK_Tray__ID', 'Invoiceable_Work_Type', 'Invoiceable_Work_DateTime', 'Invoiceable_Work_Comments' ],
                [ undef,                 $pla,           $tra,          'Prep',                  $prep_datetime,              $comments ],
                -autoquote => 1
            );

            ## This is to make sure that there was no rollback when creating the records
            my $exists = $dbc->Table_find( 'Invoiceable_Work', 'Invoiceable_Work_ID', "WHERE Invoiceable_Work_ID = $invoiceable_work_id" );
            if ( !$exists ) {
                print Message("Warning: Error in creating Invoiceable_Work $invoiceable_work_id ! ");
                Call_Stack();
                return $added;
            }

            #Add to Invoiceable_Prep table
            $invoiceable_prep_id = $dbc->Table_append_array( 'Invoiceable_Prep', [ 'FK_Invoiceable_Work__ID', 'FK_Prep__ID', 'FK_Invoice_Protocol__ID' ], [ $invoiceable_work_id, $prep, $ip_id ], -autoquote => 1 );

            $added++;

            ## get iwr information ##
            my @iwr_src = $dbc->Table_find_array(
                'Source, Source AS S2, Sample, Plate_Sample, Plate',
                ['Source.Source_ID'],
                "WHERE S2.FKOriginal_Source__ID=Source.Source_ID
                AND Sample.FK_Source__ID=S2.Source_ID
                AND Plate_Sample.FK_Sample__ID=Sample_ID
                AND Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID
                AND Plate.Plate_ID = $pla",
                -distinct => 1
            );

            foreach my $src (@iwr_src) {

                #Future Development: Add check that looks to see if the Invoiceable_Work_Reference has already been created via comparing the source ids.

                #This will be updating the Invoiceable_Work_Reference table
                $invoiceable_work_ref_id = $dbc->Table_append_array(
                    'Invoiceable_Work_Reference',
                    [   'Invoiceable_Work_Reference_ID', 'FK_Source__ID', 'Indexed',                                 'FKReferenced_Invoiceable_Work__ID',
                        'FK_Invoice__ID',                'Billable',      'FKParent_Invoiceable_Work_Reference__ID', 'Invoiceable_Work_Reference_Invoiced',
                        'FKApplicable_Funding__ID'
                    ],
                    [ undef, $src, $indexed, $invoiceable_work_id, undef, $billable, undef, 'No', $plate_funding{$pla} ],
                    -autoquote => 1
                );

                ## add check for indexed samples and call recursively with -indexed_src, -indexed parameters... ##
                $indirect += $self->record_indirectly_invoiceable_prep( -invoiceable_work_id => $invoiceable_work_id, -invoiceable_work_ref_id => $invoiceable_work_ref_id, -debug => $debug );
                $src_id    .= "$src, ";
                $total_iwr .= "$invoiceable_work_ref_id, ";
            }
        }
    }

    if ($debug) {
        Message("ADDING: $added..., Prep IDs: $prep_id, IWR IDs: $total_iwr, Indirect Records: $indirect, Source IDs: $src_id");
    }

    #flag used for testing
    if ($test_flag) {
        return $recorded;
    }

    return $added;
}

#
# Record indirectly invoiceable prep given the invoiceable_prep_id
#
# Tracks work record for:
#  - constituent samples in cases where pooled samples are worked on
#
# (indirectly invoiceable work is a copy of the original work record EXCEPT for the 'Indexed' fields and the 'FK_Source__ID' reference.  Billable status may be set independently, but is inherited)
#
# Return: number of records added (should be number of PLAs in the Prep)
#######################################
sub record_indirectly_invoiceable_prep {
#######################################
    my $self                    = shift;
    my %args                    = filter_input( \@_, -mandatory => 'invoiceable_work_id', 'invoiceable_work_ref_id' );
    my $invoiceable_work_id     = $args{-invoiceable_work_id};
    my $invoiceable_work_ref_id = $args{-invoiceable_work_ref_id};
    my $debug                   = $args{-debug};

    my $dbc   = $self->{dbc};
    my $added = 0;

    my @upstream_sources = $dbc->Table_find_array(
        'Source, Source_Pool, Invoiceable_Work IW, Invoiceable_Prep IP, Invoiceable_Work_Reference IWR',
        [ 'Source.FKOriginal_Source__ID', 'IP.FK_Prep__ID', 'IWR.Indexed' ],
        "WHERE Source.Source_ID = Source_Pool.FKParent_Source__ID AND Source_Pool.FKChild_Source__ID = IWR.FK_Source__ID AND IW.Invoiceable_Work_ID = IP.FK_Invoiceable_Work__ID AND IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IWR.Invoiceable_Work_Reference_ID = $invoiceable_work_ref_id",
        -distinct => 1
    );

    if (@upstream_sources) {

        my $num_src_upstream = int(@upstream_sources);
        foreach my $upstream_src (@upstream_sources) {
            my ( $src, $prep, $pre_index ) = split ',', $upstream_src;
            my $indexed = $num_src_upstream;
            if ($pre_index) { $indexed *= $pre_index; }

            my ($exists) = $dbc->Table_find(
                'Invoiceable_Work IW, Invoiceable_Prep IP, Invoiceable_Work_Reference IWR',
                'IWR.Invoiceable_Work_Reference_ID',
                "WHERE IW.Invoiceable_Work_ID = IP.FK_Invoiceable_Work__ID AND IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IWR.FK_Source__ID = $src AND IP.FK_Prep__ID = $prep AND IWR.FKParent_Invoiceable_Work_Reference__ID = $invoiceable_work_ref_id"
            );

            if ($exists) {
                Message("work $invoiceable_work_ref_id for SRC $src already recorded. IWR number: $exists");

            }
            else {
                my $add = $dbc->Table_append_array(
                    'Invoiceable_Work_Reference',
                    [ 'Invoiceable_Work_Reference_ID', 'FK_Source__ID', 'Indexed', 'FKReferenced_Invoiceable_Work__ID', 'FK_Invoice__ID', 'Billable', 'FKParent_Invoiceable_Work_Reference__ID', 'Invoiceable_Work_Reference_Invoiced' ],
                    [ undef,                           $src,            $indexed,  $invoiceable_work_id,                undef,            'Yes',      $invoiceable_work_ref_id,                  'No' ],
                    -autoquote => 1
                );

                #In the case of multipooling, this will make sure that this is covered
                my $indirect = $self->record_indirectly_invoiceable_prep( -invoiceable_work_id => $invoiceable_work_id, -invoiceable_work_ref_id => $add );

                $added += 1 + $indirect;
                if ($debug) {
                    Message("Added $add + $indirect indirect. Source ID: $src");
                }
            }
        }
    }

    return $added;

}

# Input: Run_ID, dbc
# Output: Added record else 0
# On insert into the Run table, a trigger will call upon this method
# This method should perform a check to see whether the Run is a invoiceable run and if the run is complete
# If so, it should call a method which will populate the invoiceable run table with it's respective information
################################
sub add_invoiceable_run_info {
################################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'dbc, run_id' );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $run_id    = $args{-run_id};
    my $backfill  = $args{-backfill};
    my $test_flag = $args{-test_flag};
    my $added     = 0;

    my @invoiceable_run = $dbc->Table_find_array( 'Run, Invoice_Run_Type IRType', [ 'IRType.Invoice_Run_Type_ID', 'IRType.Invoice_Run_Type_Status' ], "WHERE Run.Run_Type = IRType.Invoice_Run_Type_Name AND Run.Run_ID = $run_id" );

    foreach my $ir (@invoiceable_run) {
        my ( $ir_id, $status ) = split ',', $ir;

        if ( $status eq 'Active' or $backfill ) {

            #if run is invoiceable (Run is complete, protocol is in invoice_run_type and run is currently active)
            $added = $self->record_invoiceable_run( -run_id => $run_id, -ir_id => $ir_id, -test_flag => $test_flag );
        }
    }
    return $added;
}

#
# Record invoiceable Run - similar to invoiceable prep above...
#
#
# Return: number of records added (should be number of Lanes in the run)
############################
sub record_invoiceable_run {
############################
    my $self = shift;
    my %args = filter_input( \@_, -mandatory => 'run_id, ir_id' );

    my $ir_id       = $args{-ir_id};
    my $run_id      = $args{-run_id};
    my $indexed_src = $args{-indexed_src};
    my $indexed     = $args{-indexed};
    my $comments    = $args{-comments} || '';
    my $debug       = $args{-debug};
    my $test_flag   = $args{-test_flag};        # used for testing
    my $dbc         = $self->{dbc};

    my $added                   = 0;
    my $invoiceable_work_id     = '';
    my $invoiceable_work_ref_id = '';
    my $invoiceable_run_id      = '';
    my $indirect                = 0;
    my $src_id                  = '';
    my $total_iwr               = '';

    my ($recorded) = $dbc->Table_find( 'Run,Invoiceable_Run IR, Invoiceable_Work IW', 'IW.Invoiceable_Work_ID', "WHERE IR.FK_Run__ID=Run.Run_ID AND IW.Invoiceable_Work_ID = IR.FK_Invoiceable_Work__ID AND Run.Run_ID = $run_id" );

    if ($recorded) {

        # If recorded, then skip and send a debug message
        if ($debug) { $dbc->warning("Run $run_id <- already recorded (skipping)"); }
    }
    else {

        #just gets the invoiceable work info
        my @info = $dbc->Table_find_array(
            '(Plate, Run) LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID = Plate.Plate_ID',
            [ 'Plate.Plate_ID', 'FK_Tray__ID', 'Run_ID', 'Run.Run_DateTime', 'Run.Run_Type', 'Run.Billable' ],
            "WHERE Run.FK_Plate__ID = Plate.Plate_ID AND Run.Run_ID = $run_id",
            -distinct => 1
        );

        if ( int(@info) == 0 ) {
            if ($debug) {
                Message("Warning: Problem retrieving information ( Run_ID = $run_id )");
            }
        }

        require alDente::Funding;
        my %plate_funding = %{ alDente::Funding::determine_plate_funding( -dbc => $dbc, -run_ids => [$run_id] ) };

        foreach my $iw_info (@info) {
            my ( $pla, $tra, $run, $run_datetime, $type, $billable ) = split ',', $iw_info;

            # This is updating the Invoiceable_Work table
            my $invoiceable_work_id = $dbc->Table_append_array(
                'Invoiceable_Work',
                [ 'Invoiceable_Work_ID', 'FK_Plate__ID', 'FK_Tray__ID', 'Invoiceable_Work_Type', 'Invoiceable_Work_DateTime', 'Invoiceable_Work_Comments' ],
                [ undef,                 $pla,           $tra,          'Run',                   $run_datetime,               $comments ],
                -autoquote => 1
            );

            ## This is to make sure that there was no rollback when creating the records
            my $exists = $dbc->Table_find( 'Invoiceable_Work', 'Invoiceable_Work_ID', "WHERE Invoiceable_Work_ID = $invoiceable_work_id" );
            if ( !$exists ) {
                print Message("Warning: Error in creating Invoiceable_Work $invoiceable_work_id !");
                Call_Stack();
                return $added;
            }

            #Add to Invoiceable_Run table
            my $invoiceable_run_id = $dbc->Table_append_array( 'Invoiceable_Run', [ 'FK_Invoiceable_Work__ID', 'FK_Run__ID', 'FK_Invoice_Run_Type__ID' ], [ $invoiceable_work_id, $run, $ir_id ], -autoquote => 1 );

            $added++;

            ## get iwr src info ##
            my @iwr_src = $dbc->Table_find_array(
                'Source, Source AS S2, Sample, Plate_Sample, Plate',
                ['Source.Source_ID'],
                "WHERE S2.FKOriginal_Source__ID=Source.Source_ID AND Sample.FK_Source__ID=S2.Source_ID AND Plate_Sample.FK_Sample__ID=Sample.Sample_ID AND Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID AND Plate.Plate_ID = $pla",
                -distinct => 1
            );

            #Recording the Invoiceable_Work_Reference info
            foreach my $src (@iwr_src) {

                #Future development: Add check that looks to see if the Invoiceable_Work_Reference has already been created via comparing the source ids.

                #This will be updating the Invoiceable_Work_Reference table
                my $invoiceable_work_ref_id = $dbc->Table_append_array(
                    'Invoiceable_Work_Reference',
                    [   'Invoiceable_Work_Reference_ID', 'FK_Source__ID', 'Indexed',                                 'FKReferenced_Invoiceable_Work__ID',
                        'FK_Invoice__ID',                'Billable',      'FKParent_Invoiceable_Work_Reference__ID', 'Invoiceable_Work_Reference_Invoiced',
                        'FKApplicable_Funding__ID'
                    ],
                    [ undef, $src, $indexed, $invoiceable_work_id, undef, $billable, undef, 'No', $plate_funding{$pla} ],
                    -autoquote => 1
                );

                ## add check for indexed samples and call recursively with -indexed_src, -indexed parameters... ##
                $indirect += $self->record_indirectly_invoiceable_run( -invoiceable_work_id => $invoiceable_work_id, -invoiceable_work_ref_id => $invoiceable_work_ref_id,, -debug => $debug );
                $src_id    .= "$src, ";
                $total_iwr .= "$invoiceable_work_ref_id, ";
            }
        }
    }
    if ($debug) {
        Message("ADDING: $added..., Run IDs: $run_id, IWR IDs: $total_iwr, IR IDs: $invoiceable_run_id, Indirect Records: $indirect, Source IDs: $src_id");
    }

    #flag used for testing
    if ($test_flag) {
        return $recorded;
    }

    return $added;
}

#
# Record indirectly invoiceable run given the invoiceable_run_id
#
# Tracks work record for:
#  - constituent samples in cases where pooled samples are worked on
#
# (indirectly invoiceable work is a copy of the original work record EXCEPT for the 'Indexed' fields and the 'FK_Source__ID' reference.  Billable status may be set independently, but is inherited)
#
# Return: number of records added (should be number of PLAs in the Run)
#######################################
sub record_indirectly_invoiceable_run {
#######################################

    my $self                    = shift;
    my %args                    = filter_input( \@_, -mandatory => 'invoiceable_work_id', 'invoiceable_work_ref_id' );
    my $invoiceable_work_id     = $args{-invoiceable_work_id};
    my $invoiceable_work_ref_id = $args{-invoiceable_work_ref_id};
    my $debug                   = $args{-debug};

    my $dbc   = $self->{dbc};
    my $added = 0;

    my @upstream_sources = $dbc->Table_find_array(
        'Source, Source_Pool, Invoiceable_Run IR, Invoiceable_Work IW, Invoiceable_Work_Reference IWR',
        [ 'Source.FKOriginal_Source__ID', 'IR.FK_Run__ID', 'IWR.Indexed', 'IWR.Billable' ],
        "WHERE Source.Source_ID = Source_Pool.FKParent_Source__ID AND Source_Pool.FKChild_Source__ID = IWR.FK_Source__ID AND IR.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IWR.Invoiceable_Work_Reference_ID = $invoiceable_work_ref_id",
        -distinct => 1
    );

    if (@upstream_sources) {

        my $num_src_upstream = int(@upstream_sources);
        foreach my $upstream_src (@upstream_sources) {
            my ( $src, $run, $pre_index, $billable ) = split ',', $upstream_src;
            my $indexed = $num_src_upstream;
            if ($pre_index) { $indexed *= $pre_index; }

            my ($exists) = $dbc->Table_find(
                'Invoiceable_Run IR, Invoiceable_Work IW, Invoiceable_Work_Reference IWR',
                'IWR.Invoiceable_Work_Reference_ID',
                "WHERE IR.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IWR.FK_Source__ID = $src AND IR.FK_Run__ID = $run AND IWR.FKParent_Invoiceable_Work_Reference__ID = $invoiceable_work_ref_id"
            );

            if ($exists) {
                $dbc->message("work $invoiceable_work_ref_id for SRC $src already recorded. IWR number: $exists");

            }
            else {

                my ($add) = $dbc->Table_append_array(
                    'Invoiceable_Work_Reference',
                    [ 'Invoiceable_Work_Reference_ID', 'FK_Source__ID', 'Indexed', 'FKReferenced_Invoiceable_Work__ID', 'FK_Invoice__ID', 'Billable', 'FKParent_Invoiceable_Work_Reference__ID', 'Invoiceable_Work_Reference_Invoiced' ],
                    [ undef,                           $src,            $indexed,  $invoiceable_work_id,                undef,            $billable,  $invoiceable_work_ref_id,                  'No' ],
                    -autoquote => 1
                );

                #In the case of multipooling, this will make sure that this is covered
                my $indirect = $self->record_indirectly_invoiceable_run( -invoiceable_work_id => $invoiceable_work_id, -invoiceable_work_ref_id => $add );

                $added += 1 + $indirect;
                if ($debug) {
                    Message("Added $add + $indirect indirect. Source ID: $src");
                }
            }
        }
    }

    return $added;

}

###########################################################
# Gets date of data dissemination for invoiceable analyses
#
# Input: array ref of Run_Analysis_ID
# Output: array ref of dissemination dates
###########################################################
sub get_dissemination_date {
###########################################################
    my $self         = shift;
    my %args         = filter_input( \@_, -args => 'dbc, analysis_ids' );
    my $dbc          = $args{-dbc};
    my @analysis_ids = @{ $args{-analysis_ids} };

    my @dissemination_dates;
    foreach my $ra (@analysis_ids) {
        my ($d_date) = $dbc->Table_find(
            'Run_Analysis RA, Run_Analysis Alignment',
            'MAX(Alignment.Dissemination_Date)',
            "WHERE RA.FK_Run__ID = Alignment.FK_Run__ID AND RA.Run_Analysis_ID <> Alignment.Run_Analysis_ID AND Alignment.Run_Analysis_Type = 'Secondary' AND RA.Run_Analysis_ID = $ra",
            -distinct => 1
        );

        unless ($d_date) { $d_date = 'NULL' }
        push @dissemination_dates, $d_date;
    }

    return \@dissemination_dates;
}

1;

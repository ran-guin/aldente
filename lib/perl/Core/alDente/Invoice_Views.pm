###################################################################################################################################
# alDente::Invoice_Views.pm
#
#
#
#
###################################################################################################################################
package alDente::Invoice_Views;
use base alDente::Object_Views;
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
use alDente::Invoice;

use vars qw( %Configs );

#############################################
#
# Standard view for single Invoice record
#
# Return: html page
###################
sub home_page {
###################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'dbc, id' );
    my $model = $args{-model};

    my $Invoice = $model->{Invoice};
    $Invoice ||= $self->{Invoice};

    my $dbc = $args{-dbc} || $Invoice->dbc();
    my $id  = $args{-id}  || $Invoice->{id};

    if ( !$Invoice ) {
        $Invoice = new alDente::Invoice( -dbc => $dbc, -id => $id, -initialize => 0 );
    }

    my ($inv_emp_name) = $dbc->Table_find( 'Employee', 'Employee_Name', "WHERE Employee_ID = " . $Invoice->value('Invoice.FK_Employee__ID') );
    my $invoice_employee = &Link_To( $dbc->homelink(), $inv_emp_name, "&HomePage=Employee&ID=" . $Invoice->value('Invoice.FK_Employee__ID') );
    my $invoice_contact = &Link_To( $dbc->homelink(), get_FK_info( $dbc, 'FK_Contact__ID', $Invoice->value('Invoice.FK_Contact__ID') ), "&HomePage=Contact&ID=" . $Invoice->value('Invoice.FK_Contact__ID') ) if ( $Invoice->value('Invoice.FK_Contact__ID') );
    my $associated_invoiceable_works = $self->get_invoiceable_work_summary( $dbc, -invoice_ids => [$id], -selectable_field => 'Reference_ID' );

    my $invoice_code = $Invoice->value('Invoice.Invoice_Code');

    unless ($invoice_code) {
        $invoice_code = $Invoice->value('Invoice.Invoice_Draft_Name');
    }

    # Put page together from items above
    my $page = "Invoice code: " . $invoice_code . " <br /><br />" . "<span class=small>\n" . "<b>Created by:</b> $invoice_employee <br />\n" . "<b>Created date:</b> " . $Invoice->value('Invoice.Invoice_Created_Date') . " <br />\n";

    $page .= "<b>Contact:</b> $invoice_contact <br />\n" if $invoice_contact;

    $page .= "<b>Comments:</b> " . $Invoice->value('Invoice.Invoice_Comments') . "<br />" . "</b></span> <br />"

        # wrap form around work records to allow remove action
        . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Associated invoiceable_work' )
        . $self->generate_invoice_btn( -dbc => $dbc )
        . "<br><br>"
        . "<u>Associated works</u> <br>"
        . $associated_invoiceable_works
        . lbr
        . $self->append_iw_comment_from_invoice_btn( -dbc => $dbc, -from_invoice => 1 )
        . "<br><br>"
        . $self->remove_from_invoice_btn( -dbc => $dbc )
        . "<br><br>"
        . $self->remove_invoice_btn( -dbc => $dbc )
        . hidden( -name => 'Invoice_ID', -value => $id, -force => 1 )
        . end_form();

    my $homepage = Views::Table_Print(
        content => [ [ $page, $Invoice->display_Record ] ],
        print => 0
    );

    return $homepage;
}

#
# Usage:
#   my $view = $self->show_invoiceable_work(-source_id=>$src_id);
#
# Returns: Formatted view for the work completed
###########################
sub show_invoiceable_work {
###########################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $source_id = $args{-source_id};

    my $dbc   = $self->{dbc};
    my $debug = $args{-debug};

    my @id_array;
    if ( ref $source_id eq 'ARRAY' ) {
        @id_array = @$source_id;
    }
    else {
        @id_array = ($source_id);
    }

    my @results;

    ## if (! grep /,/, @id_array)
    foreach my $record (@id_array) {
        my $list = Cast_List( -list => $record, -to => 'string' );

        my $work;
        if ($list) {
            $work = $dbc->Table_retrieve_display(
                'Source, Invoiceable_Work,Invoiceable_Protocol, Invoiceable_Work_Reference',
                [ "Concat(Invoiceable_Protocol_Name,' ',Invoiceable_Protocol_Type) as Work", 'FK_Plate__ID as PLA', 'FK_Tray__ID as TRA' ],
                "WHERE Source.Source_ID = Invoiceable_Work_Reference.FK_Source__ID AND Invoiceable_Protocol_ID=FK_Invoiceable_Protocol__ID AND Source_ID IN ($list) AND Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID = Invoiceable_Work.Invoiceable_Work_ID",
                -return_html => 1,
                -no_footer   => 1,
                -debug       => $debug
            );
        }
        else {
            Message("NO list supplied");
            print HTML_Dump 'ID', $source_id, \@id_array;
        }
        push @results, $work;
    }

    return \@results;
}

######################
# Confirmation/preview page displaying list of invoiceable works
# to add to a given invoice
######################
sub confirmation_page {
######################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'dbc, id' );
    my $model = $args{-model};

    my $Invoice = $model->{Invoice};
    $Invoice ||= $self->{Invoice};

    my $dbc = $args{-dbc} || $Invoice->dbc();
    my $id  = $args{-id}  || $Invoice->{id};
    my $iwr_id = $args{-iwr_id};
    my $iw_id  = $args{-iw_id};
    my @iwr_id = @$iwr_id;

    if ( !$Invoice ) {
        $Invoice = new alDente::Invoice( -dbc => $dbc, -id => $id, -initialize => 0 );
    }

    my $invoice_code = $Invoice->value('Invoice.Invoice_Code');

    unless ($invoice_code) {
        $invoice_code = $Invoice->value('Invoice.Invoice_Draft_Name');
    }

    my ($inv_emp_name) = $dbc->Table_find( 'Employee', 'Employee_Name', "WHERE Employee_ID = " . $Invoice->value('Invoice.FK_Employee__ID') );
    my $invoice_employee = &Link_To( $dbc->homelink(), $inv_emp_name, "&HomePage=Employee&ID=" . $Invoice->value('Invoice.FK_Employee__ID') );
    my $invoice_contact = &Link_To( $dbc->homelink(), get_FK_info( $dbc, 'FK_Contact__ID', $Invoice->value('Invoice.FK_Contact__ID') ), "&HomePage=Contact&ID=" . $Invoice->value('Invoice.FK_Contact__ID') ) if ( $Invoice->value('Invoice.FK_Contact__ID') );

    my $works_to_be_added = &get_confirmation_summary( -dbc => $dbc, -iwr_id => $iwr_id );

    my $page;

    # Put page together from items above
    $page = "<div class='alert alert-danger'><b>Please confirm that you would like to add the following work items to invoice: $invoice_code</b></div>";

    $page .= "<b>Invoice code:</b> " . $invoice_code . " <br />";

    $page .= "<span class=small>\n" . "<b>Created by:</b> $invoice_employee <br />\n";

    $page .= "<b>Created date:</b> " . $Invoice->value('Invoice.Invoice_Created_Date') . " <br />\n";

    $page .= "<b>Contact:</b> $invoice_contact <br />\n" if $invoice_contact;

    $page .= "<b>Comments:</b> " . $Invoice->value('Invoice.Invoice_Comments') . "<br />" . "</b></span> <br />"

        # wrap form around work records to allow confirm action
        . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Confirm Add to Invoice' )
        . $works_to_be_added
        . &confirm_add_to_invoice_btn( -dbc => $dbc )
        . hidden( -name => 'Invoice_ID',          -value => $id,    -force => 1 )
        . hidden( -name => 'Invoiceable_Work_ID', -value => $iw_id, -force => 1 )
        . end_form();

    my $iwr_id_size = @iwr_id;

    unless ($id) {
        my $page = "<div class='alert alert-danger'><b>No invoice was selected. Please go back and select an invoice to add the following work items to:</div></b>"

            # wrap form around work records to allow confirm action
            . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Confirm Add to Invoice' )
            . $works_to_be_added
            . hidden( -name => 'Invoice_ID',          -value => $id,    -force => 1 )
            . hidden( -name => 'Invoiceable_Work_ID', -value => $iw_id, -force => 1 )
            . end_form();

        unless ( $iwr_id_size > 0 ) {
            $page = "<div class='alert alert-danger'><b>No invoice or work items were selected. Please go back and select an invoice plus work items to be added.</b></div>";
        }

        my $no_id_page = Views::Table_Print(
            content => [ [$page] ],
            print => 0
        );

        return $no_id_page;
    }

    unless ( $iwr_id_size > 0 ) {

        my $associated_invoiceable_works = $self->get_invoiceable_work_summary( $dbc, -invoice_ids => [$id], -selectable_field => 'Reference_ID' );

        # Put page together from items above
        my $page = "<div class='alert alert-danger'><b>No work items were selected. Please go back and select items to add to invoice: $invoice_code</b></div>";

        $page .= "<b>Invoice code:</b> " . $invoice_code . " <br />";

        $page .= "<span class=small>\n" . "<b>Created by:</b> $invoice_employee <br />\n";

        $page .= "<b>Created date:</b> " . $Invoice->value('Invoice.Invoice_Created_Date') . " <br />\n";

        $page .= "<b>Contact:</b> $invoice_contact <br />\n" if $invoice_contact;

        $page .= "<b>Comments:</b> " . $Invoice->value('Invoice.Invoice_Comments') . "<br />" . "</b></span> <br />"

            # wrap form around work records to allow remove action
            . alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Associated invoiceable_work' )
            . "<u>Associated works</u> <br>"
            . $associated_invoiceable_works
            . $self->remove_from_invoice_btn( -dbc => $dbc )
            . "<br><br>"
            . $self->remove_invoice_btn( -dbc => $dbc )
            . hidden( -name => 'Invoice_ID', -value => $id, -force => 1 )
            . end_form();

        my $no_works_page = Views::Table_Print(
            content => [ [ $page, $Invoice->display_Record ] ],
            print => 0
        );

        return $no_works_page;
    }

    my $confirmpage = Views::Table_Print(
        content => [ [$page] ],
        print => 0
    );

    return $confirmpage;

}

######################
# Page containing the total work count, summary of work, and downloadable excel file for an invoice
#
######################
sub invoice_page {
######################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc, invoice' );

    my $dbc     = $args{-dbc};
    my $invoice = $args{-invoice};

    my $page;

    ## include total work count in display
    $page .= &total_summary_count_table( -dbc => $dbc, -invoice => $invoice );
    $page .= lbr;

    ## include summary of work table in display
    $page .= &summary_of_work_table( -dbc => $dbc, -invoice => $invoice );

    return $page;
}

##########################
# Button to generate page containing invoice preview and link to downloadable invoice (excel)
#
##########################
sub generate_invoice_btn {
##########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc  = $args{-dbc};

    my $form_output;
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Generate Invoice', -class => 'Std', -force => 1 ), "Generates preview summary and downloadable invoice" );
    $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoice_App', -force => 1 );

    return $form_output;
}

###########################
# Summary of work to be put in an invoice (similar to that in Summary of Work (Invoicing) View)
#
# Input: Invoice_ID
# Output: HTML Table
###########################
sub summary_of_work_table {
###########################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc,invoice,library' );
    my $dbc     = $args{-dbc};
    my $invoice = $args{-invoice};

    my $Invoice = new alDente::Invoice( -dbc => $dbc, -id => $invoice, -initialize => 0 );

    my $tables = "(Invoiceable_Work IW, Invoiceable_Work_Reference IWR)
                   LEFT JOIN Plate PLA ON PLA.Plate_ID = IW.FK_Plate__ID
                   LEFT JOIN Multiplex_Run_Analysis MRA ON MRA.Multiplex_Run_Analysis_ID = IW.FK_Multiplex_Run_Analysis__ID
                   LEFT JOIN Run_Analysis RA ON RA.Run_Analysis_ID = IW.FK_Run_Analysis__ID
                   LEFT JOIN Sample MRA_Sample ON MRA_Sample.Sample_ID = MRA.FK_Sample__ID
                   LEFT JOIN Sample RA_Sample ON RA_Sample.Sample_ID = RA.FK_Sample__ID
                   LEFT JOIN Library LIB ON LIB.Library_Name = COALESCE(PLA.FK_Library__Name, MRA_Sample.FK_Library__Name, RA_Sample.FK_Library__Name)
                   LEFT JOIN Invoiceable_Run IR ON IR.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                   LEFT JOIN Solexa_Read Solread ON Solread.FK_Run__ID = IR.FK_Run__ID
                   LEFT JOIN Source SOU ON SOU.Source_ID = IWR.FK_Source__ID
                   LEFT JOIN Original_Source OS ON SOU.FK_Original_Source__ID = OS.Original_Source_ID";

    my @fields = ( 'SOU.External_Identifier AS External_ID', 'OS.Original_Source_Name AS Sample', 'LIB.Library_Name AS Library' );

    my $condition = "WHERE IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                    AND (IWR.Indexed = 0 OR IWR.Indexed IS NULL)
                    AND (Solread.End_Read_Type IS NULL OR Solread.End_Read_Type NOT LIKE 'IDX%')
                    AND IWR.Billable = 'Yes'
                    AND IWR.FK_Invoice__ID = $invoice
                    GROUP BY LIB.Library_Name
                    ORDER BY LIB.Library_Name";

    ## get invoice name (Invoice_Code -- if Invoice_Code is NULL, get Invoice_Draft_Name)
    my @invoice_name = $dbc->Table_find( 'Invoice', 'Invoice_Code', "WHERE Invoice_ID = $invoice AND Invoice_Code IS NOT NULL", -distinct => 1 );
    unless (@invoice_name) { @invoice_name = $dbc->Table_find( 'Invoice', 'Invoice_Draft_Name', "WHERE Invoice_ID = $invoice", -distinct => 1 ) }

    my @results = $dbc->Table_find_array( $tables, \@fields, $condition, -distinct => 1 );

    ## each column is an array of values, these are all ordered by Library_Name
    my ( @external_ids, @samples, @libs );
    foreach my $r (@results) {
        my ( $external_id, $sample, $lib ) = split ',', $r;
        push @external_ids, $external_id;
        push @samples,      $sample;
        push @libs,         $lib;
    }

    ## details column from Summary of Work
    my $work_summary = $Invoice->summary_of_work_details( -dbc => $dbc, -invoice => [$invoice], -library => \@libs );

    my $repeated_protocols = $Invoice->get_repeated_protocols( -dbc => $dbc, -invoice => [$invoice], -library => \@libs );
    ## Hash to display
    my %display_hash = (
        'External_ID'        => \@external_ids,
        'Sample'             => \@samples,
        'Library'            => \@libs,
        'Details'            => $work_summary,
        'Repeated Protocols' => $repeated_protocols
    );

    ## Hyperlink Library_Name to go to library homepage
    my %link_params = ( 'Library' => '&HomePage=Library&ID=<VALUE>' );

    ## Necessary for ordering
    my @keys = ( 'External_ID', 'Sample', 'Library', 'Details', 'Repeated Protocols' );

    ## include summary of work table in display
    return SDB::HTML::display_hash(
        -dbc             => $dbc,
        -hash            => \%display_hash,
        -title           => "Summary of Work for $invoice_name[0]",
        -alt_message     => "No work found on $invoice_name[0]",
        -link_parameters => \%link_params,
        -keys            => \@keys,
        -excel_link      => 1,
        -excel_name      => "_$invoice_name[0]_Summary_of_Work",
        -return_html     => 1
    );
}

###############################
# The total work count to go at the top of an invoice
#
# Input: Invoice_ID
# Output: HTML Table
###############################
sub total_summary_count_table {
###############################
    my $self    = shift;
    my %args    = &filter_input( \@_, -args => 'dbc,invoice,library' );
    my $dbc     = $args{-dbc};
    my $invoice = $args{-invoice};

    my $Invoice = new alDente::Invoice( -dbc => $dbc, -id => $invoice, -initialize => 0 );

    my $tables = "(Invoiceable_Work IW, Invoiceable_Work_Reference IWR)
                   LEFT JOIN Plate PLA ON PLA.Plate_ID = IW.FK_Plate__ID
                   LEFT JOIN Multiplex_Run_Analysis MRA ON MRA.Multiplex_Run_Analysis_ID = IW.FK_Multiplex_Run_Analysis__ID
                   LEFT JOIN Run_Analysis RA ON RA.Run_Analysis_ID = IW.FK_Run_Analysis__ID
                   LEFT JOIN Sample MRA_Sample ON MRA_Sample.Sample_ID = MRA.FK_Sample__ID
                   LEFT JOIN Sample RA_Sample ON RA_Sample.Sample_ID = RA.FK_Sample__ID
                   LEFT JOIN Library LIB ON LIB.Library_Name = COALESCE(PLA.FK_Library__Name, MRA_Sample.FK_Library__Name, RA_Sample.FK_Library__Name)
                   LEFT JOIN Source SOU ON SOU.Source_ID = IWR.FK_Source__ID
                   LEFT JOIN Original_Source OS ON SOU.FK_Original_Source__ID = OS.Original_Source_ID";

    my $field = 'LIB.Library_Name AS Library';

    my $condition = "WHERE IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                    AND (IWR.Indexed = 0 OR IWR.Indexed IS NULL)
                    AND IWR.Billable = 'Yes'
                    AND IWR.FK_Invoice__ID = $invoice
                    ORDER BY LIB.Library_Name";

    my @libs = $dbc->Table_find( $tables, $field, $condition, -distinct => 1 );

    ## get invoice name (Invoice_Code -- if Invoice_Code is NULL, get Invoice_Draft_Name)
    my @invoice_name = $dbc->Table_find( 'Invoice', 'Invoice_Code', "WHERE Invoice_ID = $invoice AND Invoice_Code IS NOT NULL", -distinct => 1 );
    unless (@invoice_name) { @invoice_name = $dbc->Table_find( 'Invoice', 'Invoice_Draft_Name', "WHERE Invoice_ID = $invoice", -distinct => 1 ) }

    ## details column from Summary of Work
    my $totals = $Invoice->get_total_work_count( -dbc => $dbc, -invoice => [$invoice], -library => \@libs );

    my ( @total_count, @total_work );
    foreach my $t (@$totals) {
        my ( $count, $work ) = split ' x ', $t;
        push @total_count, $count;
        push @total_work,  $work;
    }

    ## Hash to display
    my %display_hash = (
        'Total' => \@total_count,
        'Work'  => \@total_work
    );

    ## include summary of work table in display
    return SDB::HTML::display_hash(
        -dbc         => $dbc,
        -hash        => \%display_hash,
        -title       => "Total Work Count for $invoice_name[0]",
        -alt_message => "No work found on $invoice_name[0]",
        -excel_link  => 1,
        -excel_name  => "_$invoice_name[0]_Total_Work_Count",
        -return_html => 1
    );
}

######################
# Changes the Protocol_Status of the Invoice_Protocol
#
# Input: whether this is for the views or not
# Output: An HTML button
######################
sub change_protocol_status_btn {
######################
    my $self              = shift;
    my %args              = filter_input( \@_, -args => 'dbc' );
    my $dbc               = $args{-dbc};
    my $from_views        = $args{-from_view};                     # A parameter that needs to be set if this button is being used in a view.
    my $validation_filter = '';

    if ($from_views) {
        $validation_filter .= "this.form.target='_blank';sub_cgi_app( 'alDente::Invoice_Protocol_App');";
    }

    #    $validation_filter .= "unset_mandatory_validators(this.form);";
    $validation_filter .= "document.getElementById('invoice_protocol_status_validator').setAttribute('mandatory',1);";
    $validation_filter .= "return validateForm(this.form)";

    my $form_output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Change Active Status', -class => 'Action', -onClick => "$validation_filter", -force => 1 ), "Changes active status. Creates a new window. " );

    if ($from_views) {
        $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );
    }
    else {
        $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoice_Protocol_App', -force => 1 );
    }

    $form_output .= hspace(10) . popup_menu( -name => 'Invoice_Protocol_Status', -id => 'Invoice_Protocol_Status', -values => [ '', get_enum_list( $dbc, 'Invoice_Protocol', 'Invoice_Protocol_Status' ) ], -force => 1 );
    $form_output .= set_validator( -name => 'Invoice_Protocol_Status', -id => 'invoice_protocol_status_validator' );

    return $form_output;

}

##############################
# displays button for create new invoice protocol
#
##############################
sub create_protocol_btn {
##############################

    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ##Opens a new tab when you click on it
    ##Have read that "_blank" expression might not work with internet explorer
    my $onClick = "this.form.target='_blank';sub_cgi_app( 'alDente::Invoice_Protocol_App' )";

    my $form_output = "";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Add New Invoiceable Protocol', -class => 'Action', -onClick => $onClick, -force => 1 ), "Create new invoice protocol" );

    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );

    return $form_output;

}

######################
# Changes the Pipeline_Status of the Invoice_Pipeline
#
# Input: whether this is for the views or not
# Output: An HTML button
######################
sub change_pipeline_status_btn {
######################
    my $self              = shift;
    my %args              = filter_input( \@_, -args => 'dbc' );
    my $dbc               = $args{-dbc};
    my $from_views        = $args{-from_view};                     # A parameter that needs to be set if this button is being used in a view.
    my $validation_filter = '';

    if ($from_views) {
        $validation_filter .= "this.form.target='_blank';sub_cgi_app( 'alDente::Invoice_Pipeline_App');";
    }

    #    $validation_filter .= "unset_mandatory_validators(this.form);";
    $validation_filter .= "document.getElementById('invoice_pipeline_status_validator').setAttribute('mandatory',1);";
    $validation_filter .= "return validateForm(this.form)";

    my $form_output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Change Active Status', -class => 'Action', -onClick => "$validation_filter", -force => 1 ), "Changes active status. Creates a new window. " );

    if ($from_views) {
        $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );
    }
    else {
        $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoice_Pipeline_App', -force => 1 );
    }

    $form_output .= hspace(10) . popup_menu( -name => 'Invoice_Pipeline_Status', -id => 'Invoice_Pipeline_Status', -values => [ '', get_enum_list( $dbc, 'Invoice_Pipeline', 'Invoice_Pipeline_Status' ) ], -force => 1 );
    $form_output .= set_validator( -name => 'Invoice_Pipeline_Status', -id => 'invoice_pipeline_status_validator' );

    return $form_output;

}

##############################
# displays button for create new invoice pipeline
#
##############################
sub create_pipeline_btn {
##############################

    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ##Opens a new tab when you click on it
    ##Have read that "_blank" expression might not work with internet explorer
    my $onClick = "this.form.target='_blank';sub_cgi_app( 'alDente::Invoice_Pipeline_App' )";

    my $form_output = "";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Add New Invoiceable Pipeline', -class => 'Action', -onClick => $onClick, -force => 1 ), "Create new invoice pipeline" );

    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );

    return $form_output;

}

##############################
# displays button to create a new invoiceable run type
#
##############################
sub create_run_type_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ##Opens new tab when you click on it
    my $onClick = "this.form.target='_blank';sub_cgi_app( 'alDente::Invoice_Run_Type_App' )";

    my $form_output = "";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Add New Invoiceable Run Type', -class => 'Action', -onClick => $onClick, -force => 1 ), "Create new invoice run type" );

    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );

    return $form_output;
}

##############################
# displays button for adding work items to invoices
#
##############################
sub add_to_invoice_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $invoice_list = "  Invoice: " . &alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Invoice__ID', -filter_by_dept => 1, -search => 1, -filter => 1 );

    ##Opens a new tab when you click on it
    ##Have read that "_blank" expression might not work with internet explorer
    my $onClick = "this.form.target='_blank';sub_cgi_app( 'alDente::Invoice_App' )";

    my $form_output = "";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Add to Invoice', -class => 'Action', -onClick => $onClick, -force => 1 ), "Append work items to Invoice" );
    $form_output .= $invoice_list;
    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );

    return $form_output;
}

##############################
# displays button for confirmation of adding work items to invoices
#
##############################
sub confirm_add_to_invoice_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc  = $args{-dbc};
    my $self = shift;

    my $form_output = "";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Confirm Add to Invoice', -class => 'Action', -force => 1 ), "Append work items to Invoice" );
    $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoice_App', -force => 1 );

    return $form_output;
}

##############################
# displays button for create invoice from work items
#
##############################
sub create_into_invoice_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ##Opens a new tab when you click on it
    ##Have read that "_blank" expression might not work with internet explorer
    my $onClick = "this.form.target='_blank';sub_cgi_app( 'alDente::Invoice_App' )";

    my $form_output = "";
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Create into new Invoice', -class => 'Action', -onClick => $onClick, -force => 1 ), "Create new invoice from work items" );
    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );

    return $form_output;
}

##############################
# displays button for removing invoiceable works from invoices
#
##############################
sub remove_from_invoice_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $form_output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Remove from Invoice', -class => 'Action', -force => 1 ), "Remove work items from Invoice" );
    $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoice_App', -force => 1 );

    return $form_output;
}

##############################
# displays button for removing invoices
#
##############################
sub remove_invoice_btn {
##############################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $form_output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Remove Invoice', -class => 'Action', -force => 1 ), "Remove Invoice ( No work should be associated with this before deletion)" );
    $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoice_App', -force => 1 );

    return $form_output;
}

################################
# Input: array ref of Invoiceable_Work_Reference_IDs
# Output: HTML Table
# Creates a summary of Invoiceable Work items to be added to Invoice
################################
sub get_confirmation_summary {
###############################
    my $self   = shift;
    my %args   = &filter_input( \@_, -args => 'dbc, iwr_ids' );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $iwr_id = $args{-iwr_id};
    my $default_field_ref
        = [ 'work_id', 'funding', 'reference_id', 'library', 'library_description', 'library_strategy', 'attribute_value', 'run_id', 'run_analysis_id', 'multiplex_run_analysis_id', 'work_type', 'billable_comments', 'work_item_comments', 'Work_Status' ];

    my @iwr_id = @$iwr_id;

    if (@iwr_id) {
        my $iwr_id_string = Cast_List( -list => \@iwr_id, -to => 'String', -autoquote => 0 );

        my %iw_fields = (
            'work_id',                   'IW.Invoiceable_Work_ID AS Work_ID',
            'plate',                     'Plate.Plate_ID',
            'work_request',              'WR.Work_Request_ID',
            'library',                   'Library.Library_Name AS Library',
            'reference_id',              'IWR.Invoiceable_Work_Reference_ID AS Reference_ID',
            'library_description',       'Library.Library_Description As Library_Description',
            'library_strategy',          'LS.Library_Strategy_Name AS Library_Strategy',
            'attribute_value',           'PA.Attribute_Value',
            'attribute_id',              'PA.FK_Attribute__ID',
            'run_id',                    'IR.FK_Run__ID As Run_ID',
            'run_analysis_id',           'IW.FK_Run_Analysis__ID AS Run_Analysis_ID',
            'multiplex_run_analysis_id', 'IW.FK_Multiplex_Run_Analysis__ID AS Multiplex_Run_Analysis_ID',
            'work_type',                 'CASE WHEN IPtype.Invoice_Protocol_ID > 0 THEN IPtype.Invoice_Protocol_Name
                                     WHEN IRtype.Invoice_Run_Type_ID > 0 THEN IRtype.Invoice_Run_Type_Name
                                     WHEN IPipeline.Invoice_Pipeline_ID > 0 THEN IPipeline.Invoice_Pipeline_Name
                                     END AS Work_Type',
            'billable_comments',  'IW.Invoiceable_Work_Comments AS Billable_Comments',
            'work_item_comments', 'IW.Invoiceable_Work_Item_Comments AS Work_Item_Comments',
            'protocol',           'IPtype.FK_Lab_Protocol__ID AS Protocol',
            'work_date',          'IW.Invoiceable_Work_DateTime AS Work_Date',
            'funding',            'IWR.FKApplicable_Funding__ID AS Work_Funding',
            'funding2',           'WR.FK_Funding__ID AS Work_Funding_from_WR',
            'pla',                'IW.FK_Plate__ID AS PLA',
            'billable',           'IWR.Billable AS Billable',
            'invoice',            'IWR.FK_Invoice__ID AS Invoice',
            'run_type',           "CONCAT(MAX(Solexa_Read.Read_Length) , ' bp ' , Left(Solexa_Read.End_Read_Type , 1) , 'ET') AS Run_Type",
            'run_mode',           "GROUP_CONCAT(DISTINCT SolexaRun.SolexaRun_Mode) AS Run_Mode",
            'machine',            'RunBatch.FK_Equipment__ID AS Machine',
            'work_status',        'IWR.Invoice_Status',
            'qc_status',          'Run.QC_Status',
            'qc_status_comment',  'GROUP_CONCAT(DISTINCT Change_History.Comment) AS QC_Status_Comments'
        );

        my @fields = ();

        foreach my $d_field (@$default_field_ref) {
            my $field = $iw_fields{ lc($d_field) };
            if ($field) {
                push @fields, $field;
            }
        }

        my $works_to_be_added = $dbc->Table_retrieve_display(
            "	Invoiceable_Work IW
			    LEFT JOIN Plate ON Plate.Plate_ID = IW.FK_Plate__ID
                LEFT JOIN Multiplex_Run_Analysis MRA ON MRA.Multiplex_Run_Analysis_ID = IW.FK_Multiplex_Run_Analysis__ID
                LEFT JOIN Run_Analysis RA ON RA.Run_Analysis_ID = IW.FK_Run_Analysis__ID
                LEFT JOIN Sample MRA_Sample ON MRA_Sample.Sample_ID = MRA.FK_Sample__ID
                LEFT JOIN Sample RA_Sample ON RA_Sample.Sample_ID = RA.FK_Sample__ID
			    LEFT JOIN Library ON Library.Library_Name = COALESCE(Plate.FK_Library__Name, MRA_Sample.FK_Library__Name, RA_Sample.FK_Library__Name)
			    LEFT JOIN Invoiceable_Run IR ON IR.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                LEFT JOIN Work_Request WR ON WR.Work_Request_ID = Plate.FK_Work_Request__ID
			    LEFT JOIN Plate_Attribute AS PA ON PA.FK_Plate__ID = Plate.Plate_ID AND PA.FK_Attribute__ID = 246
			    LEFT JOIN Library_Strategy AS LS ON LS.Library_Strategy_ID = PA.Attribute_Value
			    LEFT JOIN Invoiceable_Prep IP ON IP.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                LEFT JOIN Invoiceable_Run_Analysis ON Invoiceable_Run_Analysis.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
			    LEFT JOIN Invoice_Protocol IPtype ON IPtype.Invoice_Protocol_ID = IP.FK_Invoice_Protocol__ID
			    LEFT JOIN Invoice_Run_Type IRtype ON IRtype.Invoice_Run_Type_ID = IR.FK_Invoice_Run_Type__ID
                LEFT JOIN Invoiceable_Work_Reference IWR ON IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
                LEFT JOIN Run ON Run.Run_ID = IR.FK_Run__ID
                LEFT JOIN RunBatch ON Run.FK_RunBatch__ID=RunBatch_ID
                LEFT JOIN Change_History ON Record_ID = CAST(Run.Run_ID AS CHAR(40)) AND Change_History.FK_DBField__ID = 3540
                LEFT JOIN Invoice_Pipeline AS IPipeline ON IPipeline.Invoice_Pipeline_ID = Invoiceable_Run_Analysis.FK_Invoice_Pipeline__ID",
            \@fields,
            "	WHERE IWR.Invoiceable_Work_Reference_ID IN ($iwr_id_string)
                    GROUP BY IW.Invoiceable_Work_ID
                ORDER BY IWR.FK_Source__ID, IW.Invoiceable_Work_DateTime ",
            -title           => 'List of Invoiceable Works to be Added',
            -return_html     => 1,
            -list_in_folders => ['IW_Comments'],
            -alt_message     => "No records found for invoiceable_work",
            -space_words     => 1,
            -style           => "white-space: normal; "
        );

        return $works_to_be_added;
    }
    else {
        Message('Required mandatory input parameter not recognized.');
        return;
    }

}

################################
# Input: Library, iw, invoice array field refs
# optionally: a list of fields to display using keys of iw_field hash , specify a selectable field
# Creates a brief invoiceable work summary (small table)
# Output: html table
################################
sub get_invoiceable_work_summary {
################################
    my $self              = shift;
    my %args              = &filter_input( \@_, -args => 'dbc,library_names|iw_ids|invoice_ids,field_list,selectable_field', -mandatory => 'dbc,library_names|iw_ids|invoice_ids' );
    my $dbc               = $args{-dbc} || $self->param('dbc');
    my $library_names     = $args{-library_names};
    my $iw_ids            = $args{-iw_ids};
    my $invoice_ids       = $args{-invoice_ids};
    my $default_field_ref = [ 'work_id', 'reference_id', 'library', 'library_description', 'library_strategy', 'attribute_value', 'run_id', 'work_type', 'billable_comments', 'work_item_comments', 'Work_Status' ];
    my $custom_field_ref = $args{-field_list} || $default_field_ref;    #provide a custom field list, or it will use default
    my $selectable_field = $args{-selectable_field};
    my $no_title         = $args{-no_title};

    my $title;
    unless ($no_title) { $title = 'List of invoiceable work' }

    #Call_Stack();
    #print HTML_Dump $custom_field_ref;
    my $condition        = '';
    my $extra_left_joins = '';

    if ($iw_ids) {
        my $iw_id_string = Cast_List( -list => $iw_ids, -to => 'String' );
        $condition = " IW.Invoiceable_Work_ID IN ( $iw_id_string ) ";
    }
    elsif ($invoice_ids) {
        my $invoice_id_string = Cast_List( -list => $invoice_ids, -to => 'String' );
        $condition = " IWR.FK_Invoice__ID IN ( $invoice_id_string ) ";
    }
    elsif ($library_names) {
        my $libraries = Cast_List( -list => $library_names, -to => 'String', -autoquote => 1 );
        $condition = " Library_Name IN ( $libraries ) ";
    }
    else {
        Message('Required mandatory input parameter not recognized.');
        return;
    }

    #  custom_field_ref is an empty array; use default fields
    if ( !@$custom_field_ref ) {
        $custom_field_ref = $default_field_ref;
    }

    my %iw_fields = (
        'work_id',             'IW.Invoiceable_Work_ID AS Work_ID',
        'plate',               'Plate.Plate_ID',
        'work_request',        'COALESCE(WR.Work_Request_ID, WR_Analysis.Work_Request_ID) AS Work_Request_ID',
        'library',             'Library_Name AS Library',
        'reference_id',        'IWR.Invoiceable_Work_Reference_ID AS Reference_ID',
        'library_description', 'Library.Library_Description As Library_Description',
        'library_strategy',    'LS.Library_Strategy_Name AS Library_Strategy',
        'attribute_value',     'PA.Attribute_Value',
        'attribute_id',        'PA.FK_Attribute__ID',
        'run_id',              'IR.FK_Run__ID As Run_ID',
        'work_type',           'CASE WHEN IPtype.Invoice_Protocol_ID > 0 THEN IPtype.Invoice_Protocol_Name
                                     WHEN IRtype.Invoice_Run_Type_ID > 0 THEN IRtype.Invoice_Run_Type_Name
                                     WHEN IPipeline.Invoice_Pipeline_ID > 0 THEN IPipeline.Invoice_Pipeline_Name
                                     END AS Work_Type',
        'billable_comments',  'IW.Invoiceable_Work_Comments AS Billable_Comments',
        'work_item_comments', 'IW.Invoiceable_Work_Item_Comments AS Work_Item_Comments',
        'protocol',           'IPtype.FK_Lab_Protocol__ID AS Protocol',
        'work_date',          'IW.Invoiceable_Work_DateTime AS Work_Date',
        'funding',            'IWR.FKApplicable_Funding__ID AS Work_Funding',
        'funding2',           'COALESCE(WR.FK_Funding__ID, WR_Analysis.FK_Funding__ID) AS Work_Funding_from_WR',
        'pla',                'IW.FK_Plate__ID AS PLA',
        'billable',           'IWR.Billable AS Billable',
        'invoice',            'IWR.FK_Invoice__ID AS Invoice',
        'run_type',           "CONCAT(MAX(Solexa_Read.Read_Length) , ' bp ' , Left(Solexa_Read.End_Read_Type , 1) , 'ET') AS Run_Type",
        'run_mode',           "GROUP_CONCAT(DISTINCT SolexaRun.SolexaRun_Mode) AS Run_Mode",
        'machine',            'RunBatch.FK_Equipment__ID AS Machine',
        'work_status',        'IWR.Invoice_Status',
        'qc_status',          'Run.QC_Status',
        'qc_status_comment',  'GROUP_CONCAT(DISTINCT Change_History.Comment) AS QC_Status_Comments'
    );

    my @fields           = ();
    my $require_slx_read = 0;

    #adds fields in custom order, or default if not specified
    foreach my $c_field (@$custom_field_ref) {
        my $field = $iw_fields{ lc($c_field) };
        if ($field) {
            push @fields, $field;
            if ( lc( $c_field eq 'run_type' ) ) {
                $require_slx_read = 1;    # flag to add tables and condition for solexa_read info
            }
        }
    }

    if ($require_slx_read) {
        $extra_left_joins = " LEFT JOIN Solexa_Read ON Solexa_Read.FK_Run__ID= IR.FK_Run__ID
                              LEFT JOIN SolexaRun ON SolexaRun.FK_Run__ID=IR.FK_Run__ID";
        $condition .= " AND ( Solexa_Read.End_Read_Type IS NULL OR Solexa_Read.End_Read_Type NOT LIKE 'IDX%' )";
    }

    my $associated_invoiceable_works = $dbc->Table_retrieve_display(
        "	Invoiceable_Work IW, Library_Source
			LEFT JOIN Plate ON Plate.Plate_ID = IW.FK_Plate__ID
            LEFT JOIN Multiplex_Run_Analysis MRA ON MRA.Multiplex_Run_Analysis_ID = IW.FK_Multiplex_Run_Analysis__ID
            LEFT JOIN Sample MRA_Sample ON MRA_Sample.Sample_ID = MRA.FK_Sample__ID
            LEFT JOIN Run_Analysis RA ON RA.Run_Analysis_ID = IW.FK_Run_Analysis__ID
            LEFT JOIN Sample RA_Sample ON RA_Sample.Sample_ID = RA.FK_Sample__ID
            LEFT JOIN Library ON Library_Name = COALESCE(Plate.FK_Library__Name, MRA_Sample.FK_Library__Name, RA_Sample.FK_Library__Name)
			LEFT JOIN Invoiceable_Run IR ON IR.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
    /* added */
            LEFT JOIN Work_Request WR ON WR.Work_Request_ID = Plate.FK_Work_Request__ID
    /* ###### */
            LEFT JOIN Pipeline_Attribute ON Pipeline_Attribute.FK_Pipeline__ID = RA.FKAnalysis_Pipeline__ID
            LEFT JOIN Work_Request WR_Analysis ON (WR_Analysis.FK_Library__Name = Library.Library_Name AND WR_Analysis.FK_Goal__ID = Pipeline_Attribute.Attribute_Value) 
			LEFT JOIN Plate_Attribute AS PA ON PA.FK_Plate__ID = Plate.Plate_ID AND PA.FK_Attribute__ID = 246
			LEFT JOIN Library_Strategy AS LS ON LS.Library_Strategy_ID = PA.Attribute_Value
			LEFT JOIN Invoiceable_Prep IP ON IP.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
            LEFT JOIN Invoiceable_Run_Analysis ON Invoiceable_Run_Analysis.FK_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
			LEFT JOIN Invoice_Protocol IPtype ON IPtype.Invoice_Protocol_ID = IP.FK_Invoice_Protocol__ID
			LEFT JOIN Invoice_Run_Type IRtype ON IRtype.Invoice_Run_Type_ID = IR.FK_Invoice_Run_Type__ID
            LEFT JOIN Invoiceable_Work_Reference IWR ON IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID
            LEFT JOIN Source ChildSource ON ChildSource.FKOriginal_Source__ID = IWR.FK_Source__ID
            LEFT JOIN Run ON Run.Run_ID = IR.FK_Run__ID
            LEFT JOIN RunBatch ON Run.FK_RunBatch__ID=RunBatch_ID
            LEFT JOIN Change_History ON Record_ID = CAST(Run.Run_ID AS CHAR(40)) AND Change_History.FK_DBField__ID = 3540
            LEFT JOIN Invoice_Pipeline AS IPipeline ON IPipeline.Invoice_Pipeline_ID = Invoiceable_Run_Analysis.FK_Invoice_Pipeline__ID
            $extra_left_joins ",
        \@fields,
        "	WHERE $condition AND (IWR.Indexed = 0 OR IWR.Indexed IS NULL) AND Library_Source.FK_Library__Name = Library.Library_Name AND Library_Source.FK_Source__ID = ChildSource.Source_ID
        	GROUP BY IW.Invoiceable_Work_ID
		ORDER BY IWR.FK_Source__ID, IW.Invoiceable_Work_DateTime ",
        -title            => "$title",
        -return_html      => 1,
        -selectable_field => $selectable_field,
        -list_in_folders  => ['IW_Comments'],
        -alt_message      => "No records found for invoiceable_work",
        -space_words      => 1,
        -style            => "white-space: normal; ",
    );

    return $associated_invoiceable_works;
}

######################
sub redirect_to_LC_invoiceable_work_view_btn {
######################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my ( $view_root, $view_sub_path ) = alDente::Tools::get_standard_Path( -type => 'view', -group => 8, -structure => 'DATABASE' );
    my $view_filepath = $view_root . $view_sub_path . 'general/LC_-_Invoiceable_Work.yml';

    if ( -e $view_filepath ) {
        my $append_iw_comment_btn = submit( -name => 'ViewRedirect', -value => "Show invoiceable work", -class => 'Action' );
        $append_iw_comment_btn .= hspace(10) . hidden( -name => 'Show invoiceable work', -value => $view_filepath, -force => 1 );

        return $append_iw_comment_btn;
    }

    return;
}

######################
# Used to create credit when it is needed.
#
#
# Output: An html button
#
######################
sub credit_invoice_btn {
######################
    my %args       = filter_input( \@_, -args => 'dbc' );
    my $dbc        = $args{-dbc};
    my $invoice_id = $args{-id};

    #    $validation_filter .= "unset_mandatory_validators(this.form);";
    #    $validation_filter    .= "document.getElementById('credit_status_validator').setAttribute('mandatory',1);";
    my $validation_filter .= "document.getElementById('credit_comments_validator').setAttribute('mandatory',1);";
    $validation_filter    .= "return validateForm(this.form)";

    my $credit_button = Show_Tool_Tip( submit( -name => 'rm', -value => "Create Credit", -class => 'Action', -force => 1 ), "Adds a credit to the Invoice" );
    $credit_button .= hidden( -name => 'cgi_application', -value => 'alDente::Invoice_App', -force => 1 );

    #    $credit_button .= hspace(10) . popup_menu( -name => 'Credit_Status', -id => 'Credit_Status', -values => [ '', get_enum_list($dbc, 'Invoiceable_Work_Reference', 'Invoice_Status' ) ], -force => 1 );
    #    $credit_button .= set_validator( -name => 'Credit_Status', -id => 'credit_status_validator' );
    $credit_button .= set_validator( -name => 'Credit_Comments', -id => 'credit_comments_validator' ) . " Invoiceable Work Comments: " . textfield( -name => 'Credit_Comments', -size => 30 );
    $credit_button .= hidden( -name => 'Invoice_ID', -value => $invoice_id );

    return $credit_button;
}

######################
# Generate a button for appending Invoiceable_Work comments
# It is mainly used in views
#
# <snip>
#	alDente::Invoiceable_Work_Views::append_iw_comment_btn(-dbc=>$self->{dbc}, -from_view => 1 );
# <snip>
#
# Return:
#	HTML string
######################
sub append_iw_comment_from_invoice_btn {
######################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $validation_filter = '';
    $validation_filter .= "unset_mandatory_validators(this.form);";
    $validation_filter .= "document.getElementById('IW_comments_validator').setAttribute('mandatory',1);";
    $validation_filter .= "return validateForm(this.form)";

    my $output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Append Invoiceable Work Item Comment', -class => 'Action', -onClick => "$validation_filter", -force => 1 ), "Append comments to the selected Invoiceable Work" );

    $output .= hspace(10) . set_validator( -name => 'IW_Comments', -id => 'IW_comments_validator' ) . " Work Item Comments: " . textfield( -name => 'IW_Comments', -size => 30, -default => '' );

    $output .= hidden( -name => 'cgi_application', -value => 'alDente::Invoice_App', -force => 1 );

    return $output;
}

1;

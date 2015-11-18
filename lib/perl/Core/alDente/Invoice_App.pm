##################
# Invoice_App.pm #
##################
#
# This module is used to monitor Invoices for Library and Project objects.
#
package alDente::Invoice_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##
#use base alDente::CGI_App;
use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;

use alDente::Invoice;
use alDente::Invoice_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Benchmark);
my $q;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home'                                 => 'home_page',
        'New Invoice'                          => 'new_invoice',
        'Add to Invoice'                       => 'confirm_add_to_invoice',
        'Confirm Add to Invoice'               => 'add_to_invoice',
        'Create into new Invoice'              => 'new_invoice',
        'Create append new Invoice'            => 'create_append_new_invoice',
        'Remove from Invoice'                  => 'remove_from_invoice',
        'Remove Invoice'                       => 'remove_invoice',
        'Create Credit'                        => 'create_credit',
        'Generate Invoice'                     => 'generate_invoice',
        'Append Invoiceable Work Item Comment' => 'append_iw_comment_from_invoice',
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##################
sub home_page {
##################

    my $self = shift;

    my $dbc = $self->param('dbc');

    $q = $self->query();

    my $id = $q->param("Invoice_ID") || $q->param('ID');

    my $invoice = new alDente::Invoice( -dbc => $dbc, -id => $id, -initialize => 0 );
    my $invoice_view = new alDente::Invoice_Views( -model => { 'Invoice' => $invoice } );

    return $invoice_view->home_page( -dbc => $dbc );
}

############################
sub new_invoice {
############################
    my $self  = shift;
    my $q     = $self->query();
    my $dbc   = $self->param('dbc');
    my @iw_id = $q->param('Mark');     #invoiceable_work ids from view

    my $grey   = $q->param('Grey');
    my $preset = $q->param('Preset');

    my %grey;
    my %preset;
    my %hidden;
    my %list;

    my $navigator = 1;
    my $repeat;
    my $append_html = '';              #add html for hidden parameters
    my %button      = ();

    if ($grey)   { %grey   = %$grey }
    if ($preset) { %preset = %$preset }

    my $timestamp = date_time();

    $preset{Invoice_Created_Date} = $timestamp;
    my $user_id = $dbc->get_local('user_id');
    my $user = $dbc->get_FK_info( -field => 'FK_Employee__ID', -id => $user_id );
    $grey{FK_Employee__ID} = $user;

    my @invoiceable_work_id = $q->param('Mark');

    #Convert Invoiceable_Work_IDs into Invoiceable_Work_Reference_IDs
    my @iwr_id;
    my $invoiceable_work_id_castlist;

    my $invoice_item = alDente::Invoice->new( -dbc => $dbc );

    if (@invoiceable_work_id) {
        $invoiceable_work_id_castlist = Cast_List( -list => \@invoiceable_work_id, -to => 'string', -autoquote => 0 );
        @iwr_id = $dbc->Table_find(
            "Invoiceable_Work_Reference",
            "Invoiceable_Work_Reference_ID",
            "WHERE FKReferenced_Invoiceable_Work__ID in ($invoiceable_work_id_castlist) 
        								 AND (FKParent_Invoiceable_Work_Reference__ID = 0 OR FKParent_Invoiceable_Work_Reference__ID IS NULL)"
        );
    }

    if (@iw_id) {

        $navigator = 0;

        $append_html .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Invoice_App', -force => 1 ) . "\n";
        $append_html .= $q->hidden( -name => 'Mark', -value => \@iw_id, -force => 1 ) . "\n";

        $append_html .= alDente::Invoice_Views::get_confirmation_summary( -dbc => $dbc, -iwr_id => \@iwr_id );

        %button = ( "rm" => "Create append new Invoice" );
    }

    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Invoice', -target => 'Database', -append_html => $append_html );
    $table->configure( -grey => \%grey, -preset => \%preset, -omit => \%hidden, -list => \%list );

    return $table->generate( -navigator_on => $navigator, -return_html => 1, -repeat => $repeat, -button => \%button );
}

##################################################
# Confirmation page for adding items to Invoice
##################################################
sub confirm_add_to_invoice {
##################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $invoice_id;
    my $invoice_par = &get_Table_Param( -dbc => $dbc, -table => "Invoiceable_Work_Reference", -field => "FK_Invoice__ID" );
    my @invoice_par = $invoice_par;
    if ($invoice_par) {
        $invoice_id = $dbc->get_FK_ID( -field => "FK_Invoice__ID", -value => $invoice_par );
    }

    my @invoiceable_work_id = $q->param('Mark');

    #Convert Invoiceable_Work_IDs into Invoiceable_Work_Reference_IDs
    my @invoiceable_work_reference_id;
    my $invoiceable_work_id_castlist;

    if (@invoiceable_work_id) {
        $invoiceable_work_id_castlist = Cast_List( -list => \@invoiceable_work_id, -to => 'string', -autoquote => 0 );
        @invoiceable_work_reference_id = $dbc->Table_find(
            "Invoiceable_Work_Reference",
            "Invoiceable_Work_Reference_ID",
            "WHERE FKReferenced_Invoiceable_Work__ID in ($invoiceable_work_id_castlist) 
        								 AND (FKParent_Invoiceable_Work_Reference__ID = 0 OR FKParent_Invoiceable_Work_Reference__ID IS NULL)"
        );
    }

    my $invoice = new alDente::Invoice( -dbc => $dbc, -id => $invoice_id, -initialize => 0 );

    my $invoice_view = new alDente::Invoice_Views( -model => { 'Invoice' => $invoice } );
    my $page = $invoice_view->confirmation_page( -dbc => $dbc, -iwr_id => \@invoiceable_work_reference_id, -iw_id => \@invoiceable_work_id );

    return $page;

}

##################### Adapted #####################
##############################
# Add to Invoice
#
##############################
sub add_to_invoice {
##############################
    my $self       = shift;
    my %args       = filter_input( \@_, 'dbc' );
    my $dbc        = $args{-dbc} || $self->param('dbc');
    my $invoice_id = $args{-invoice_id};
    my $q          = $self->query;
    my $work_invoice_message;
    my $updated_count;
    if ( !$invoice_id ) {
        my $invoice_par = &get_Table_Param( -dbc => $dbc, -table => "Invoiceable_Work_Reference", -field => "FK_Invoice__ID" );
        my @invoice_par = $invoice_par;
        if ($invoice_par) {
            $invoice_id = $dbc->get_FK_ID( -field => "FK_Invoice__ID", -value => $invoice_par );
        }

        if ( !$invoice_id ) {
            Message('Invoice_ID was not found, unable to continue.');
            return;
        }
    }

    my @invoiceable_work_id = $q->param('Invoiceable_Work_ID');

    unless (@invoiceable_work_id) {
        @invoiceable_work_id = $q->param('Mark');
    }

    my $test = \@invoiceable_work_id;

    #Convert Invoiceable_Work Ids to Invoiceable_Work_Reference IDs since we need to use Invoiceable_Work_Reference_ids.
    my @invoiceable_work_reference_id;
    my $invoiceable_work_id_castlist;

    if (@invoiceable_work_id) {
        $invoiceable_work_id_castlist = Cast_List( -list => \@invoiceable_work_id, -to => 'string', -autoquote => 0 );
        @invoiceable_work_reference_id = $dbc->Table_find(
            "Invoiceable_Work_Reference",
            "Invoiceable_Work_Reference_ID",
            "WHERE FKReferenced_Invoiceable_Work__ID in ($invoiceable_work_id_castlist) 
        								 AND (FKParent_Invoiceable_Work_Reference__ID = 0 OR FKParent_Invoiceable_Work_Reference__ID IS NULL)"
        );
    }

    my $invoice = new alDente::Invoice( -dbc => $dbc, -id => $invoice_id, -initialize => 0 );

    #    my $Progress = new SDB::Progress( -title => "Adding to Invoice" );
    #    my $count    = scalar(@invoiceable_work_reference_id);
    #    my $done     = 0;
    #
    #    foreach my $iwr_id (@invoiceable_work_reference_id) {
    #        my @iwr_id;
    #        push( @iwr_id, $iwr_id );
    #        $updated_count = $invoice->add_invoice_check( -dbc => $dbc, -ids => \@iwr_id );
    #        $done++;
    #        my $completion = int( 100 * $done / $count );
    #        $Progress->update( $completion, $iwr_id );
    #    }
    $updated_count = $invoice->add_invoice_check( -dbc => $dbc, -ids => \@invoiceable_work_reference_id );
    if ($updated_count) {
        print Message("$updated_count work items have been added to the following invoice:");
    }
    else {
        print Message ("No work items were added to the following invoice:");
    }
    my $invoice_view = new alDente::Invoice_Views( -model => { 'Invoice' => $invoice } );
    my $page = $invoice_view->home_page( -dbc => $dbc );

    return $page;
}

##############################
# Create new invoice and append invoiceable_work items
#
##############################
sub create_append_new_invoice {
##############################
    my $self = shift;
    my %args = filter_input( \@_, 'dbc' );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Invoice', -object => $self, -dbc => $dbc );

    # add a new invoice first
    my $invoice_item = alDente::Invoice->new( -dbc => $dbc );
    my $invoice_id = $invoice_item->save_invoice_info( -dbc => $dbc, -fields => $fields, -values => $values );

    # update invoiceable_work items to reference new invoice
    my $page;
    if ($invoice_id) {
        $page = $self->add_to_invoice( -dbc => $dbc, -invoice_id => $invoice_id );
    }
    else {
        Message("Warning: There was a problem in creating the new invoice.");
        return;
    }

    return $page;
}

##############################
# Remove work items from the invoice
#
##############################
sub remove_from_invoice {
##############################
    my $self = shift;
    my %args = filter_input( \@_, 'dbc' );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my @invoiceable_work_reference_id = $q->param('Mark');
    my $invoice_id                    = $q->param('Invoice_ID');

    my $invoice = new alDente::Invoice( -dbc => $dbc, -id => $invoice_id, -initialize => 0 );

    if (@invoiceable_work_reference_id) {

        #    	###
        #    	my $iwr_ids = Cast_List( -list => \@invoiceable_work_reference_id, -to => 'String' );
        #    	my @referenced_iw_id = $dbc->Table_find( "Invoiceable_Work_Reference", "FKReferenced_Invoiceable_Work__ID", "WHERE Invoiceable_Work_Reference_ID in ($iwr_ids)" );
        #    	my $referenced_iw_id_list = Cast_List( -list => \@referenced_iw_id, -to => 'String' );
        #
        #    	my @invoiceable_work_reference_ids = $dbc->Table_find( "Invoiceable_Work_Reference", "Invoiceable_Work_Reference_ID", "WHERE FKReferenced_Invoiceable_Work__ID in ($referenced_iw_id_list)" );
        #    	###
        my $updated = $invoice->update_invoiceable_work_invoice( -dbc => $dbc, -iwr_ids => \@invoiceable_work_reference_id );
        my $invoice_code = $dbc->get_FK_info( 'FK_Invoice__ID', $invoice_id );

        if ($updated) {
            Message("Note: Removed $updated work items from invoice: $invoice_code");
        }
    }

    my $invoice_view = new alDente::Invoice_Views( -model => { 'Invoice' => $invoice } );

    return $invoice_view->home_page( -dbc => $dbc );
}

##############################
# Removes invoices when there is no Invoiceable_Work associated with it.
#
##############################
sub remove_invoice {
##############################
    my $self = shift;
    my %args = filter_input( \@_, 'dbc' );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $invoice_id = $q->param('Invoice_ID');

    my $invoice = new alDente::Invoice( -dbc => $dbc, -id => $invoice_id, -initialize => 0 );

    # Checks number of Invoiceable_Work on an invoice before removing
    my ($IW_count) = $dbc->Table_find( "Invoiceable_Work IW, Invoiceable_Work_Reference IWR", "COUNT(DISTINCT IW.Invoiceable_Work_ID)", "WHERE IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND IWR.FK_Invoice__ID = $invoice_id" );

    if ( $IW_count > 0 ) {
        print Message("There are still invoiceable work items attached to this invoice!<br>You must remove all invoiceable work before deleting!");
        my $invoice_view = new alDente::Invoice_Views( -model => { 'Invoice' => $invoice } );
        return $invoice_view->home_page( -dbc => $dbc );
    }

    my $deleted = $dbc->delete_record( -table => 'Invoice', -field => 'Invoice_ID', -value => "$invoice_id" );

    if ($deleted) {
        print Message("Invoice $invoice_id has been deleted!");
    }
    else {
        print Message("Error when deleting Invoice!");
    }

    return;
}

##############################
# Add a work item which is already invoiced, to another invoice
# will apply as credit
#
##############################
sub create_credit {
##############################
    my $self         = shift;
    my %args         = filter_input( \@_, 'dbc' );
    my $dbc          = $args{-dbc} || $self->param('dbc');
    my $q            = $self->query;
    my $id           = $q->{Invoice_ID}->[0];
    my $invoice      = new alDente::Invoice( -dbc => $dbc, -id => $id, -initialize => 0 );
    my $invoice_view = new alDente::Invoice_Views( -model => { 'Invoice' => $invoice } );
    my $updated;
    my $invoice_code = $dbc->get_FK_info( 'FK_Invoice__ID', $id );
    my $iwr_ref      = $q->{Mark};
    my @iwr_array    = @$iwr_ref;
    my $comments     = $q->{Credit_Comments}->[0];

    my $iwr_list = join( ',', @iwr_array );

    my @info = $dbc->Table_find_array(
        "Invoiceable_Work_Reference",
        [ 'FK_source__ID', 'Indexed', 'FKReferenced_Invoiceable_Work__ID', 'Billable', 'FKParent_Invoiceable_Work_Reference__ID', 'Invoiceable_Work_Reference_Invoiced' ],
        "WHERE Invoiceable_Work_Reference_ID in ($iwr_list) OR FKParent_Invoiceable_Work_Reference__ID in ($iwr_list)"
    );

    foreach my $iw_info (@info) {

        my ( $source, $indexed, $reference, $billable, $parent ) = split( ',', $iw_info );
        if ( $indexed == 0 ) { $indexed = undef; }
        if ( $parent == 0 )  { $parent  = undef; }
        $dbc->Table_append_array(
            'Invoiceable_Work_Reference',
            [ 'Invoiceable_Work_Reference_ID', 'FK_Source__ID', 'Indexed', 'FKReferenced_Invoiceable_Work__ID', 'FK_Invoice__ID', 'Billable', 'FKParent_Invoiceable_Work_Reference__ID', 'Invoiceable_Work_Reference_Invoiced', 'Invoice_Status' ],
            [ undef,                           $source,         $indexed,  $reference,                          $id,              $billable,  $parent,                                   'Yes',                                 'Credit' ],
            -autoquote => 1
        );

        $dbc->Table_update_array(
            "Invoiceable_Work",
            ['Invoiceable_Work_Item_Comments'],
            ["$comments"],
            "WHERE Invoiceable_Work.Invoiceable_Work_ID IN ($reference)",
            -append_only_fields => ['Invoiceable_Work_Item_Comments'],
            -autoquote          => 1
        );

        $updated++;
    }

    print Message("$updated credit records were added and given to Invoice $invoice_code");

    return $invoice_view->home_page( -dbc => $dbc );
}

############################
# Display page containing a preview of an invoice and link to download invoice (excel)
#
############################
sub generate_invoice {
############################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $id           = $q->param('Invoice_ID');
    my $invoice      = new alDente::Invoice( -dbc => $dbc, -id => $id, -initialize => 0 );
    my $invoice_view = new alDente::Invoice_Views( -model => { 'Invoice' => $invoice } );

    return $invoice_view->invoice_page( -dbc => $dbc, -invoice => $id );

}

#####################################
# Calls Invoiceable_Work method to append invoiceable work comments
#
#####################################
sub append_iw_comment_from_invoice {
#####################################
    my $self = shift;
    my %args = filter_input( \@_, 'dbc' );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $iw_comments = $q->param('IW_Comments');
    my @ids         = $q->param('Mark');
    my $invoice     = $q->param('Invoice_ID');
    if ( !@ids ) { $dbc->message("No records are selected for appending comments!"); return }

    my $id_list = Cast_List( -list => \@ids, -to => 'String' );
    @ids = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FKReferenced_Invoiceable_Work__ID', "WHERE Invoiceable_Work_Reference_ID in ($id_list)", -distinct => 1 );

    my $ok;
    if (@ids) {
        require alDente::Invoiceable_Work;
        $ok = alDente::Invoiceable_Work::append_invoiceable_work_comment( -dbc => $dbc, -invoiceable_work_id => \@ids, -iw_comments => $iw_comments );
    }
    else {
        $dbc->message("No Invoiceable_Work record found. Comments are not appended!");
    }

    my $Invoice_View = new alDente::Invoice_Views( -dbc => $dbc );
    return $Invoice_View->home_page( -dbc => $dbc, -id => $invoice );
}

return 1;

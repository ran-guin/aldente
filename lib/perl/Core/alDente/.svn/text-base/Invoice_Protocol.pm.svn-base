###################################################################################################################################
# alDente::Invoice_Protocol.pm
#
#
###################################################################################################################################
package alDente::Invoice_Protocol;

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

use vars qw( %Configs );

#####################
sub new {
    #####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Invoice_Protocol' );
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'Invoice_Protocol', -value => $id );
        $self->load_Object();
    }

    return $self;
}

##################################
# Input: Invoice Protocol ID
# Sends email notification to projects invoicing if an invoice protocol
# has its status changed
#
#
##################################
sub invoice_protocol_status_change_notification {
##################################
    my %args = &filter_input( \@_, -args => 'dbc,id', -mandatory => 'dbc,id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my ($status) = $dbc->Table_find_array( 'Change_History', [ 'Old_Value', 'New_Value' ], "WHERE FK_DBField__ID = 4624 AND Record_ID IN ($id) AND Modified_Date > DATE_SUB(NOW(), INTERVAL 1 MINUTE) ORDER BY Modified_Date DESC LIMIT 1" );
    my ( $old_status, $new_status ) = split ',', $status;

    if ( ( $old_status ne $new_status ) && $old_status ) {

        # fields for the html table
        my @invoice_protocol_fields = ( 'Lab_Protocol_Name', 'Invoice_Protocol_Status AS New_Invoice_Protocol_Status', "'$old_status' AS Old_Invoice_Protocol_Status", 'Invoice_Protocol_Name', 'Invoice_Protocol_Type', 'Tracked_Prep_Name' );

        # html table with given Invoice Protocol ID
        my $changed_invoice_protocol_html
            = $dbc->Table_retrieve_display( "Invoice_Protocol, Lab_Protocol", \@invoice_protocol_fields, "WHERE FK_Lab_Protocol__ID = Lab_Protocol_ID AND Invoice_Protocol_ID IN ($id)", -title => "Updated Invoice Protocol:", -return_html => 1 );

        my $subject_str = "Invoice Protocol Status Change Notification";
        my $msg         = "<p ></p>The status of the following invoice protocol has been changed:<br />";
        $msg .= "$changed_invoice_protocol_html";

        require alDente::Subscription;
        my $ok = alDente::Subscription::send_notification(
            -dbc          => $dbc,
            -name         => "Invoice Protocol Status Change",
            -from         => 'aldente@bcgsc.ca',
            -subject      => "$subject_str",
            -body         => $msg,
            -content_type => 'html'
        );

        return $ok;
    }
}

##################################
# Input: Lab Protocol ID
# Sends email notification to projects invoicing if a lab protocol
# has been archived but the associated invoice protocol is still active
#
#
##################################
sub lab_protocol_status_change_notification {
##################################
    my %args = &filter_input( \@_, -args => 'dbc,id', -mandatory => 'dbc,id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my ($status) = $dbc->Table_find_array( 'Change_History', [ 'Old_Value', 'New_Value' ], "WHERE FK_DBField__ID = 1055 AND Record_ID IN ($id) AND Modified_Date > DATE_SUB(NOW(), INTERVAL 1 MINUTE) ORDER BY Modified_Date DESC LIMIT 1" );
    my ( $old_status, $new_status ) = split ',', $status;

    my ($invoice_protocol_info) = $dbc->Table_find_array( 'Invoice_Protocol', [ 'Invoice_Protocol_Name', 'Invoice_Protocol_Status' ], "WHERE FK_Lab_Protocol__ID IN ($id)" );
    my ( $invoice_protocol, $inv_protocol_status ) = split ',', $invoice_protocol_info;

    if ( ( $old_status ne $new_status ) && ( $new_status eq 'Archived' ) && ( $inv_protocol_status eq 'Active' ) ) {

        # fields for the html table
        my @invoice_protocol_fields = ( 'Lab_Protocol_Name', 'Lab_Protocol_Status AS New_Lab_Protocol_Status', "'$old_status' AS Old_Lab_Protocol_Status", 'Invoice_Protocol_Name', 'Invoice_Protocol_Status', 'Invoice_Protocol_Type', 'Tracked_Prep_Name' );

        # html table with given Invoice Protocol ID
        my $changed_lab_protocol_html
            = $dbc->Table_retrieve_display( "Invoice_Protocol, Lab_Protocol", \@invoice_protocol_fields, "WHERE FK_Lab_Protocol__ID = Lab_Protocol_ID AND Lab_Protocol_ID IN ($id)", -title => "Archived Lab Protocol:", -return_html => 1 );

        my $subject_str = "Lab Protocol Status Change Notification (Invoiceable)";
        my $msg         = "<p ></p>The following lab protocol has been archived but is still associated to an active invoice protocol:<br />";
        $msg .= "$changed_lab_protocol_html";

        require alDente::Subscription;
        my $ok = alDente::Subscription::send_notification(
            -dbc          => $dbc,
            -name         => "Invoice Protocol Status Change",
            -from         => 'aldente@bcgsc.ca',
            -subject      => "$subject_str",
            -body         => $msg,
            -content_type => 'html'
        );

        return $ok;
    }
}

##################################
# Input: Invoice Protocol ID
# Sends email notification to projects invoicing if a new
# invoice protocol has been created
#
#
##################################
sub new_invoice_protocol_notification {
##################################
    my %args = &filter_input( \@_, -args => 'dbc,id', -mandatory => 'dbc,id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    # fields for the html table
    my @invoice_protocol_fields = ( 'Lab_Protocol_Name', 'Invoice_Protocol_Name', 'Invoice_Protocol_Type', 'Tracked_Prep_Name', 'Invoice_Protocol_Status', 'Priority', 'Abbrev AS Abbreviated_Name' );

    # html table with given Invoice Protocol ID
    my $new_invoice_protocol_html
        = $dbc->Table_retrieve_display( "Invoice_Protocol, Lab_Protocol", \@invoice_protocol_fields, "WHERE FK_Lab_Protocol__ID = Lab_Protocol_ID AND Invoice_Protocol_ID IN ($id)", -title => "New Invoice Protocol:", -return_html => 1 );

    my $subject_str = "New Invoice Protocol Notification";
    my $msg         = "<p ></p>The following protocol has been made invoiceable:<br />";
    $msg .= "$new_invoice_protocol_html";

    require alDente::Subscription;
    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => "Invoice Protocol Status Change",
        -from         => 'aldente@bcgsc.ca',
        -subject      => "$subject_str",
        -body         => $msg,
        -content_type => 'html'
    );

    return $ok;
}

1;


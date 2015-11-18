###################################################################################################################################
# alDente::Sample_Request_Views.pm
#
# Interface generating methods for the Sample_Request MVC  (associated with Sample_Request.pm, Sample_Request_App.pm)
#
###################################################################################################################################
package alDente::Sample_Request_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##
## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::DB_Form;
## alDente modules
use alDente::Web;

use vars qw( %Configs );

my $q = new CGI;
#####################
sub new {
#####################
    my $this  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $Model = $args{-model};
    my $self  = {};                     ## if object is NOT a DB_Object ... otherwise...
    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->{dbc}   = $dbc;
    $self->{Model} = $Model;

    return $self;
}

################
sub main_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my $top_block
        = alDente::Form::start_alDente_form($dbc)
        . Show_Tool_Tip( submit( -name => 'rm', -value => "New Request", -class => "Action" ), "Adding New Request" )
        . hspace(10)
        . submit( -name => 'rm', -value => "Search Requests", -class => "Std" )
        . hidden( -name => 'cgi_application', -value => 'alDente::Sample_Request_App', -force => 1 )
        . end_form();
    my $intiated = $dbc->Table_retrieve_display(
        'Sample_Request LEFT JOIN Shipment ON FK_Sample_Request__ID = Sample_Request_ID',
        [ 'Sample_Request_ID', 'Sample_Count', 'FK_Funding__ID', 'Sample_Request.Addressee', 'Sample_Request.FK_Contact__ID', 'Sample_Request.FK_Organization__ID', 'Request_Comments', "GROUP_CONCAT(Shipment_ID) AS Shipments" ],
        "WHERE Request_Status='Initiated'",
        -title       => 'Active Requests',
        -distinct    => 1,
        -group_by    => 'Sample_Request_ID',
        -order_by    => 'Sample_Request_ID',
        -alt_message => 'No active requests available',
        -return_html => 1,
    );

    my $sent = $dbc->Table_retrieve_display(
        'Sample_Request LEFT JOIN Shipment ON FK_Sample_Request__ID = Sample_Request_ID',
        [ 'Sample_Request_ID', 'Sample_Count', 'FK_Funding__ID', 'Sample_Request.Addressee', 'Sample_Request.FK_Contact__ID', 'Sample_Request.FK_Organization__ID', 'Request_Comments', "GROUP_CONCAT(Shipment_ID) AS Shipments" ],
        "WHERE Request_Status='Sent'",
        -title       => 'Sent Requests',
        -distinct    => 1,
        -group_by    => 'Sample_Request_ID',
        -order_by    => 'Sample_Request_ID',
        -alt_message => 'No sent requests available',
        -return_html => 1,
    );

    my $top = alDente::Form::init_HTML_table( "Sample Request Page", -margin => 'on' );
    $top->Set_Row( [ LampLite::Login_Views->icons( 'Sample_Request', -dbc => $dbc ), $top_block . hr . $intiated . hr . $sent ] );
    return $top->Printout(0);
}

################
sub home_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $id   = $args{-id};

    my $label = $self->label( -id => $id );

    my $actions = $self->actions( -id => $id );

    my $info = $dbc->Table_retrieve_display(
        'Shipment', [ "Shipment_ID", 'Shipment_Status', 'Shipment_Sent', 'Shipment_Received' ],
        "WHERE FK_Sample_Request__ID=$id",
        -title       => 'Shipments',
        -alt_message => 'No shipments for this request',
        -return_html => 1,
    );

    my $Sample_Request = new alDente::Sample_Request( -dbc => $dbc, -id => $id );
    my $details = $Sample_Request->display_Record();

    my %colspan;
    $colspan{1}->{1} = 2;    ## set the Heading to span 2 columns

    return &Views::Table_Print( content => [ [ $label . '<HR>' . $actions . '<HR>' . $info, "&nbsp&nbsp&nbsp&nbsp", $details ] ], -colspan => \%colspan, -spacing => "10", print => 0 );
}

################
sub display_New_Request {
################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $self->{dbc};
    my $user_id = $dbc->get_local('user_id');

    my $new_Request = new SDB::DB_Form( -table => 'Sample_Request', -dbc => $dbc );

    $new_Request->configure(
        -grey => {},
        -omit => {
            'Completion_Date'     => '',
            'FK_Employee__ID'     => $user_id,
            'Request_Status'      => 'Initiated',
            'FK_Object_Class__ID' => 'Source',
        },

    );

    return $new_Request->generate( -return_html => 1 );
}

################
sub display_New_Shipment {
################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $self->{dbc};
    my $id      = $args{-id};
    my $user_id = $dbc->get_local('user_id');

    my %info = $dbc->Table_retrieve( 'Sample_Request', [ 'Sample_Request_ID', 'Sample_Count', 'Sample_Request.Addressee', 'Sample_Request.FK_Contact__ID', 'Sample_Request.FK_Organization__ID', 'Request_Comments' ], "WHERE Sample_Request_ID = $id" );

    my $new_Request = new SDB::DB_Form( -table => 'Shipment', -dbc => $dbc );

    $new_Request->configure(
        -grey => {
            'Addressee'                   => $info{Addressee}[0],
            'FKRecipient_Employee__ID'    => $user_id,
            'FKSupplier_Organization__ID' => $info{FK_Organization__ID}[0],
            'FK_Sample_Request__ID'       => $info{Sample_Request_ID}[0],
            'FK_Contact__ID'              => $info{FK_Contact__ID}[0],
            'Shipment_Type'               => 'Roundtrip',
        },
        -omit => { 'FK_Submissoion__ID' => '', },
    );

    return $new_Request->generate( -return_html => 1 );
}

################
sub actions {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $id   = $args{-id};

    require alDente::Rack_Views;
    my $page = alDente::Rack_Views::manifest_form( -dbc => $dbc, -sample_request_id => $id );

    #        = alDente::Form::start_alDente_form($dbc, '')
    #        . $q->submit( -name => 'rm', -value => "New Shipment", -class => "Action" )
    #        . hspace(10)
    #        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Sample_Request_App', -force => 1 )
    #        . $q->hidden( -name => 'FK_Sample_Request__ID', -value => $id, -force => 1 )
    #        . $q->end_form();

    return $page;
}

################
sub large_label {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $id   = $args{-id};

    my %info = $dbc->Table_retrieve(
        'Sample_Request LEFT JOIN Organization ON Sample_Request.FK_Organization__ID = Organization_ID LEFT JOIN Contact On FK_Contact__ID = Contact_ID LEFT JOIN Funding ON FK_Funding__ID = Funding_ID',
        [ 'Sample_Request_ID', 'Sample_Count', 'Addressee', 'Organization_Name', 'Contact_Name', 'Funding_Code', 'Request_Comments' ],
        "WHERE Sample_Request_ID = $id"
    );

    my @label = ( "Request ID: " . $info{Sample_Request_ID}[0], $info{Contact_Name}[0], $info{Organization_Name}[0], $info{Sample_Count}[0] . " tubes for SOW: " . $info{Funding_Code}[0], "Notes: " . $info{Request_Comments}[0] );

    return $self->standard_label( -label => \@label, -label_format => 1, -size => 25, -label_name => 'large' );
}

################
sub label {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $id   = $args{-id};

    my %info = $dbc->Table_retrieve(
        'Sample_Request LEFT JOIN Organization ON Sample_Request.FK_Organization__ID = Organization_ID LEFT JOIN Contact On FK_Contact__ID = Contact_ID LEFT JOIN Funding ON FK_Funding__ID = Funding_ID',
        [ 'Sample_Request_ID', 'Sample_Count', 'Addressee', 'Organization_Name', 'Contact_Name', 'Funding_Code' ],
        "WHERE Sample_Request_ID = $id"
    );

    my @label = ( "Request ID: " . $info{Sample_Request_ID}[0], $info{Contact_Name}[0], $info{Organization_Name}[0], $info{Sample_Count}[0] . " tubes for SOW: " . $info{Funding_Code}[0], );

    return $self->standard_label( -label => \@label, -print => 1, -label_format => 1, -size => 25, -label_name => 'large' );
}

################
sub standard_label {
################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $dbc          = $self->{dbc};
    my $border       = defined $args{-border} ? $args{-border} : 1;
    my $colour       = $args{-colour} || '#ffffff';
    my $label        = $args{ -label };                               ## array ref of values to be printed by lines
    my $print_option = $args{ -print };                               ###  adds print option
    my $size         = $args{-size};                                  ## font size
    my $label_format = $args{-label_format};                          ##id
    my $label_name   = $args{-label_name};
    unless ($label) {return}

    my $text;
    my $open_wrapper  = "<Table cellspacing=0 cellpadding=2 border=$border><TR><TD bgcolor='$colour' nowrap>";
    my $close_wrapper = "</TD></TR></Table>";
    my $print_section = alDente::Form::start_alDente_form( $dbc, '' );

    my @labels     = @$label;
    my $line_count = @labels;
    my $index;
    for my $line (@labels) {
        $text .= $line . vspace();
        $index++;
        $print_section
            .= $q->hidden( -name => 'l_text' . $index, -value => $line, -force => 1 )
            . $q->hidden( -name => 'l_text' . $index . '.posx', -value => 0, -force => 1 )
            . $q->hidden( -name => 'l_text' . $index . '.posy', -value => ( $size * ( $index - 1 ) + 5 ), -force => 1 )
            . $q->hidden( -name => 'l_text' . $index . '.size', -value => $size, -force => 1 )
            . $q->hidden( -name => 'l_text' . $index . '.style', -value => 'text', -force => 1 );
    }

    $print_section
        .= "<B>Printer:</B>"
        . alDente::Tools::search_list( -name => "FK_Printer__ID", -element_name => 'Printer', -condition => "FK_Label_Format__ID=$label_format", -force => 1 )
        . set_validator( 'Printer', -mandatory => 1 )
        . hspace(5)
        . $q->submit( -name => 'rm', -value => "Print Label", -class => "Std" )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Barcode_App', -force => 1 )
        . $q->hidden( -name => 'Lcount',          -value => $line_count,            -force => 1 )
        . $q->hidden( -name => 'Rcount',          -value => 0,                      -force => 1 )
        . $q->hidden( -name => 'No_Return',       -value => 1,                      -force => 1 )

        ## Over riding barcode so it disapears
        . $q->hidden( -name => 'Label Name',    -value => $label_name, -force => 1 )
        . $q->hidden( -name => 'barcode',       -value => '',          -force => 1 )
        . $q->hidden( -name => 'barcode.style', -value => 'text',      -force => 1 )
        . $q->hidden( -name => 'barcode.posx',  -value => 200,         -force => 1 )
        . $q->hidden( -name => 'barcode.posy',  -value => 0,           -force => 1 )
        . $q->hidden( -name => 'barcode.size',  -value => 0,           -force => 1 )

        . $q->end_form();

    my $page = $open_wrapper . $text . $close_wrapper . vspace(2);

    if ($print_option) {
        $page .= $print_section;
    }

    return $page;
}

1;

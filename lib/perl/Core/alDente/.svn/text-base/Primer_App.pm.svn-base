####################
# Primer_App.pm #
####################
#
# This is a Primer for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Primer_App;

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

use base alDente::CGI_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;
use alDente::Primer;
use alDente::Primer_Plate;

##############################
# global_vars                #
##############################

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                           => 'entry_page',
            'Home'                              => 'main_page',
            'List'                              => 'list_page',
            'Receive Primer Plate as Tubes'     => 'receive_primer_plate_as_tubes',
            'Regenerate Primer Order'           => 'regenerate_primer_order_from_primer_plate',
            'Order Repeated Primer Plate'       => 'order_repeated_primer_plate',
            'Mark Primer Plates as Ordered'     => 'mark_primer_plates_as_ordered',
            'Generate Custom Primer Multiprobe' => 'generate_custom_primer_multiprobe',
            'Delete Primer Plate Orders'        => 'delete_primer_orders',
            'Mark Primer Plates as Canceled'    => 'mark_primer_plates_as_canceled'
        }
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');
    my $primer_obj = new alDente::Primer( -dbc => $dbc );
    $self->param( 'Primer_Model' => $primer_obj );
    return $self;
}

###############
## run modes ##
###############
###########################
sub entry_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('ID');

    unless ($id) { return $self->main_page( -dbc => $dbc ) }
    if ( $id =~ /,/ ) { return $self->list_page( -dbc => $dbc, -list => $id ) }
    else              { return $self->home_page( -dbc => $dbc, -id => $id ) }
    return 'Error: Inform LIMS';
}

###########################
sub list_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $list = $q->param('list') || $args{-list};
    my $view = $dbc->Table_retrieve_display(
        -table       => "Primer",
        -fields      => [ 'Primer_ID', 'Primer_Name', 'Primer_Type', 'Primer_OrderDateTime', 'Primer_Status', 'Purity' ],
        -condition   => "WHERE Primer_ID IN ($list)",
        -return_html => 1,
    );
    return $view;
}

###########################
sub main_page {
###########################
    #
    # General Equipment home page...
    #
    # This is NOT used for scanner mode
    #
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $page = 'Under Construction (Primer Main Page)';

    return $page;
}

###########################
sub home_page {
###########################
    my $self = shift;
    my $q    = $self->query;
    my %args = @_;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    my $id = $q->param('ID');
    if ($id) { return $self->display_primer_home( -id => $id, -dbc => $dbc ) }

    return;
}

################################
# receive_primer_plate_as_tubes
#
# Return: create solutions for each well of primer plate and then delete primer plate
############################
sub receive_primer_plate_as_tubes {
############################
    my $self                = shift;
    my %args                = &filter_input( \@_ );
    my $q                   = $self->query;
    my $dbc                 = $self->param('dbc');
    my $org                 = $q->param('FK_Organization__Name');
    my @primer_list         = $q->param("PlateRow");
    my $delete_primer_plate = $q->param('delete_primer_plate');
    $self->param('Primer_Model')->receive_primer_plate_as_tubes( -primer_plate_ids => \@primer_list, -org_name => $org, -delete_primer_plate => $delete_primer_plate );
    return "";
}

################################
# regenerate_primer_order_from_primer_plate
# Refactored from Button_Options:  elsif ( param("Regenerate Primer Order From Primer Plate") ) {#
#
# Return:
############################
sub regenerate_primer_order_from_primer_plate {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @primer_list = $q->param("PlateRow");
    require Sequencing::Primer;
    my $po = new Sequencing::Primer( -dbc => $dbc );
    $po->display_primer_order( -primer_plate_range => join( ',', @primer_list ) );

    return "";
}

#################################
# Order repeated primer plate
# ###############################
sub order_repeated_primer_plate {
#################################
    my $self              = shift;
    my %args              = &filter_input( \@_ );
    my $q                 = $self->query;
    my $dbc               = $self->param('dbc');
    my $new_names_list    = $q->param('New_Primer_Plate_Name');
    my @primer_plate_list = $q->param("PlateRow");
    my @new_names         = Cast_List( -list => $new_names_list, -to => 'array', -autoquote => 0 ) if ($new_names_list);

    ## create Primer_Plate record
    my $primer_obj = new alDente::Primer( -dbc => $dbc );
    foreach my $i ( 0 .. $#primer_plate_list ) {
        my $primer_plate_id = $primer_plate_list[$i];
        my ($info) = $dbc->Table_find(
            "Primer_Plate,Solution,Stock,Stock_Catalog",
            "Primer_Plate_Name,Stock_Catalog_Name,FK_Solution__ID",
            "WHERE FK_Solution__ID = Solution_ID and FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and Primer_Plate_ID=$primer_plate_id"
        );
        my ( $primer_plate_name, $stock_name, $copied_sol ) = split ',', $info;
        my $new_name;
        if ( defined $new_names[$i] ) {
            $new_name = $new_names[$i];
        }
        if ( !$new_name ) {
            $new_name = "$primer_plate_name Repeated";
        }
        my $new_solution_id = $primer_obj->copy_primer_plate( -primer_plate_id => $primer_plate_id, -new_name => $new_name, -stock_name => $stock_name );
        if ($new_solution_id) {

            # update primer plate status to 'Ordered'
            $dbc->Table_update_array( "Primer_Plate", ["Primer_Plate_Status"], ['Ordered'], "WHERE FK_Solution__ID=$new_solution_id", -autoquote => 1 );
            Message("sol$new_solution_id is the repeated primer order of sol$copied_sol");
        }
        else {
            Message("Error occurred when creating repeated primer order of sol$copied_sol");
        }
    }

    return;
}

################################
# mark_primer_plates_as_ordered
# Refactored from Button_Options:  elsif ( param("Mark Primer Plates as Ordered") ) {#
#
# Return:
############################
sub mark_primer_plates_as_ordered {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @primer_list = $q->param("PlateRow");
    $self->param('Primer_Model')->mark_plates_as_ordered( -primer_ids => join( ',', @primer_list ) );

    return "";
}

################################
# mark_primer_plates_as_canceled
# Refactored from Button_Options:  elsif ( param("Mark Primer Plates as Canceled") ) {#
#
# Return:
############################
sub mark_primer_plates_as_canceled {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @primer_list = $q->param("PlateRow");
    $self->param('Primer_Model')->mark_plates_as_canceled( -primer_ids => join( ',', @primer_list ) );

    return "";
}

################################
# generate_custom_primer_multiprobe
# Refactored from Button_Options:  elsif ( param('Generate Custom Primer Multiprobe') ) {
#
# Return:
############################
sub generate_custom_primer_multiprobe {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @primer_ids = $q->param('PlateRow');

    # get unique items
    @primer_ids = @{ &unique_items( \@primer_ids ) };

    # check if all the primer ids are remapped
    #require Sequencing::Multiprobe;
    #&Sequencing::Multiprobe::prompt_multiprobe_limit(-dbc=>$dbc, -primer_plate_id => join( ',', @primer_ids ), -type => "Primer" );

    require alDente::ReArray_Views;
    my $output = &alDente::ReArray_Views::prompt_multiprobe_limit( -dbc => $dbc, -primer_plate_id => join( ',', @primer_ids ), -type => "Primer" );

    return $output;
}

############################
sub delete_primer_orders {
############################
    my $self                = shift;
    my %args                = &filter_input( \@_ );
    my $q                   = $self->query;
    my $dbc                 = $self->param('dbc');
    my @ids                 = $q->param('PlateRow');
    my $delete_primers_flag = $q->param('Delete_Primers');

    my $list = join ',', @ids;
    my $primer_obj = new alDente::Primer_Plate( -dbc => $dbc );

    for my $id (@ids) {
        my $confirm_delete = $primer_obj->confirm_deletion_validity( -ids => $id );
        if ($confirm_delete) {
            $primer_obj->delete_primer_plate_orders( -ids => $id, -del_primers => $delete_primers_flag );
        }
        else {
            Message "Deletion aborted: $id";
        }
    }
    return;
}

######################################################
##          View                                    ##
######################################################
############################
sub display_primer_home {
############################

    my $self       = shift;
    my %args       = @_;
    my $dbc        = $args{-dbc} || $self->param('dbc');
    my $primer_id  = $args{-id} || $self->param('funding_id');
    my $primer_obj = $self->param('Primer_Model');
    my $db_obj     = $primer_obj->get_db_object( -dbc => $dbc, -id => $primer_id );

    my $page = Views::sub_Heading( "Primer Home Page", 1 );
    $page
        .= "<Table cellpadding=10 width=100%><TR>"
        . "</TD><TD height=1 valign=top>"
        . $self->display_intro( -id => $primer_id, -dbc => $dbc )
        . "</TD><TD rowspan=3 valign=top>"
        . $db_obj->display_Record( -tables => ['Primer'], -index => "index $primer_id", -truncate => 40 )
        . &vspace(4)
        . "</TD>\n";
    $page .= "</TD></TR></Table>";
    return $page;
}
##########################
sub display_intro {
##########################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $id   = $args{-id};

    my @info = $dbc->Table_find(
        -table     => 'Primer',
        -fields    => "Primer_Name,Primer_Sequence",
        -condition => "WHERE Primer_ID = $id"
    );
    ( my $name, my $sequence ) = split ',', $info[0];

    my $page = "ID:    $id" . vspace() . "Name:  $name" . vspace();
    $page .= "Sequence:  $sequence" . vspace() if $sequence;
    $page .= '<HR>';
    return $page;
}

############################
sub display_delete_Primer_Plate_table {
############################
    my $self = shift;
    my $q    = $self->query;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $id   = $args{-id};

    my @primer_plate_status = ('');
    push( @primer_plate_status, $dbc->Table_find( 'Primer_Plate', 'distinct Primer_Plate_Status' ) );
    my @primer_types = ('');
    push( @primer_types, $dbc->Table_find( "Primer", "distinct Primer_Type", "WHERE 1" ) );
    @primer_types = @{ &unique_items( \@primer_types ) };

    my $rearray_utilities = HTML_Table->init_table( -title => "Find Primer Plate to delete", -width => 600, -toggle => 'on' );
    $rearray_utilities->Set_Border(1);
    $rearray_utilities->Set_Row(
        [   $q->submit(
                -name  => "rm",
                -value => "View Primer Plates",
                -style => "background-color:lightgreen"
            ),
            "<BR> Primer Plate ID: <BR>"
                . $q->textfield( -name => "Primer Plate ID" )

                #                . "<BR> From Order Date: <BR>"
                #                . $q-> textfield( -name => "Primer From Date" )
                . "<BR>Status:<BR>"
                . $q->popup_menu(
                -name    => "Primer Plate Status",
                -values  => \@primer_plate_status,
                -default => 'To Order'
                )

                #                . "<BR>Type:<BR>"
                #                .$q->  popup_menu( -name => "Primer Types", -values => \@primer_types )
                #                . "<BR>Notes:<BR>"
                #                . $q-> textfield( -name => "Primer Notes" )
        ]
    );

    my $output
        = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Rearray_Utilities" )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App', -force => 1 )
        . $q->hidden( -name => 'button options',  -value => 'bioinformatics',       -force => 1 )
        . $rearray_utilities->Printout(0)
        . $q->end_form();
    return $output;

}

return 1;

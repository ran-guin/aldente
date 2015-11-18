################################################################################
# Array.pm
#
# This module handles Container microarray-based functions
#
###############################################################################
package alDente::Array;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Array.pm - This module handles Container Microarray based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container Microarray based functions<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(alDente::Container);

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use Data::Dumper;
use URI::Escape;
use RGTools::Barcode;
use Benchmark;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DB_Object;
use SDB::Session;
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

use alDente::Container;
use alDente::Container_Views;

##############################
# global_vars                #
##############################
use vars qw($current_plates $Sess);
use vars qw( $Connection );
use vars qw(%Benchmark);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

########
sub new {
########
    #
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id         = $args{-id};
    my $ids        = $args{-ids};
    my $plate_id   = $args{-plate_id} || 0;
    my $attributes = $args{-attributes};                                                              ## allow inclusion of attributes for new record
    my $encoded    = $args{-encoded} || 0;                                                            ## reference to encoded object (frozen)

    my ($class) = ref($this) || $this;

    my $self = alDente::Container->new( -dbc => $dbc, -encoded => $encoded, -type => 'Array' );

    bless $self, $class;

    $self->add_tables('Array');

    if ($plate_id) {
        $self->primary_value( -table => 'Plate', -value => $plate_id );                               ## same thing as above..
        $self->load_Object( -type => 'Array', -plate_id => $plate_id );
        $self->{plate_id} = $plate_id;
        $self->{id}       = $self->get_data("Array_ID");
    }
    elsif ($id) {
        $self->{id} = $id;                                                                            ## list of current plate_ids
        $self->primary_value( -table => 'Array', -value => $id );                                     ## same thing as above..
        $self->load_Object( -type => 'Array', -plate_id => $id );
        $self->{plate_id} = $self->get_data('Array_ID');

    }
    elsif ($attributes) {

        #	$self->add_Record(-attributes=>$attributes);
    }
    return $self;
}

#################
sub home_page {
#################
    # Simple home page for Tube (when id is defined).
    #
    my $self = shift;
    my %args = @_;

    return "This method has been deprecated... refactor by moving to Array_Views if necessary and using standard Container_Views::display_record_page ...";

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $brief = $args{-brief};

    print &alDente::Container::Display_Input($dbc);

    print "<Table cellpadding=10 width=100%><TR><TD valign=top height=1 nowrap>";

    print &alDente::Container_Views::foreign_label( $self->{plate_id}, -verbose => 1, -border => 0, -colour => 'white' );

    my $details = &Link_To( $dbc->config('homelink'), 'Edit this record', "&Search=1&Table=Plate&Search+List=$self->{plate_id}", $Settings{LINK_COLOUR}, ['newwin'] ) . &vspace(4) . $self->display_Record( -tables => [ 'Plate', 'Array' ], -truncate => 40 )
        unless $brief;
    my $ancestry = &alDente::Container_Views::fail_toolbox( -plates => $current_plates, -tree => 'Ancestry Details', -dbc => $dbc ) unless $scanner_mode;

    print "</TD><TD height=1 valign=top>" . &alDente::Container_Views::view_Ancestry( -view => 1, -id => $self->{plate_id}, -return_html => 1, -dbc => $dbc );
    print "</TD><TD rowspan=3 valign=top>" . $details;

    print "</TD></TR><TR><TD colspan=2 height=1 valign=top>";

    my @show = ( 'FK_Library__Name', 'Plate_Number', 'Plate_Size', 'Plate_Format.Plate_Format_Type', 'Plate_Format.Well_Capacity_mL' );

    print $self->Array_button_options(
        -dbc      => $dbc,
        -plate_id => $self->{plate_id},
        -details  => $details,
        -ancestry => $ancestry,
    );
    print "</TD></TR><TR><TD></TD></TR></Table>";

    return;
}

########################################################
# Options below home_info for Tube containers
#
#
##########################
sub Array_button_options {
##########################
    #
    # generate buttons / links that exist as options
    #
    my $self     = shift;
    my %args     = @_;
    my $dbc      = $args{-dbc};
    my $plate_id = $args{-plate_id} || $self->{plate_id};
    my $ancestry = $args{-ancestry};
    my %layers;

    return "This method has been deprecated... refactor by moving to Array_Views if necessary and using standard Container_Views::display_record_page ...";

    $layers{'Ancestry'} = $ancestry if $ancestry;

    my $output;
    unless ( ( $plate_id =~ /[1-9]/ ) && ( $plate_id !~ /,/ ) ) {return}    ## do not allow options unless 1 (and only 1) id given.

    $output .= alDente::Container_Views::Plate_button_options( -dbc => $dbc, -id => $plate_id, -wrap => 0, -add_layers => \%layers );    ## start with standard Plate button options ##A

    return $output;
}

#####################
# Create an array by applying a microarray to a tube
#####################
sub create_array {
#####################
    my $self = shift;
    my %args = @_;

    my $dbc     = $self->{dbc};
    my $user_id = $dbc->get_local('user_id');

    my $parent_id     = $args{-plate_id};                       # (Scalar) Plate ID of the parent tube
    my $microarray_id = $args{-microarray_id};                  # (Scalar) Microarray_ID of the microarray to be used
    my $test_status   = $args{-test_status} || 'Production';    # (Scalar) test status of the microarray
    my $application   = $args{-application} || 'Affymetrix';    # (Scalar) the application of the microarray

    # add sanity check - parent has to be a tube
    my ($tube_id) = $dbc->Table_find( "Tube", "Tube_ID", "WHERE FK_Plate__ID = $parent_id" );
    unless ($tube_id) {
        Message("Source is not a tube, aborting...");
        return 0;
    }

    # add sanity check - microarray has to exist
    my ($microarray_id_check) = $dbc->Table_find( "Microarray", "Microarray_ID", "WHERE Microarray_ID = $microarray_id and Microarray_Status = 'Unused'" );
    unless ($microarray_id_check) {
        Message("Microarray ID does not exist or has been used, aborting...");
        return 0;
    }

    # get the chip name
    my ($chip_name) = $dbc->Table_find( "Genechip_Type, Genechip", "Genechip_Type_Name", "WHERE FK_Genechip_Type__ID = Genechip_Type_ID and FK_Microarray__ID = $microarray_id" );

    # get format for a Genechip
    my ($format_id) = $dbc->Table_find( "Plate_Format", "Plate_Format_ID", "WHERE Plate_Format_Type='Genechip'" );
    my %plate_info = $dbc->Table_retrieve( "Plate,Tube", [ "FK_Library__Name", "FKOriginal_Plate__ID", "FK_Sample_Type__ID", "FK_Pipeline__ID", "FK_Branch__Code" ], "WHERE FK_Plate__ID=Plate_ID AND Plate_ID = $parent_id" );

    my $library_name       = $plate_info{FK_Library__Name}[0];
    my $original_plate     = $plate_info{FKOriginal_Plate__ID}[0];
    my $FK_Sample_Type__ID = $plate_info{FK_Sample_Type__ID}[0];
    my $pipeline           = $plate_info{FK_Pipeline__ID}[0];
    my $branch_code        = $plate_info{FK_Branch__Code}[0];
    my %Plate_values;

    my @fields = (
        'Plate.Plate_Size',           'Plate.FK_Library__Name',   'Plate.FK_Employee__ID',   'Plate.Plate_Created', 'Plate.FK_Rack__ID', 'Plate.Plate_Number',
        'Plate.FK_Plate_Format__ID',  'Plate.FKParent_Plate__ID', 'Plate.Plate_Test_Status', 'Plate.Plate_Status',  'Plate.Failed',      'Plate.Plate_Type',
        'Plate.FKOriginal_Plate__ID', 'FK_Sample_Type__ID',       'FK_Microarray__ID',       'FK_Pipeline__ID',     'FK_Branch__Code'
    );
    my @values = ( '1-well', $library_name, $user_id, &date_time(), 1, 1, $format_id, $parent_id, $test_status, 'Active', 'No', 'Array', $original_plate, $FK_Sample_Type__ID, $microarray_id, $pipeline, $branch_code );

    $dbc->smart_append( -tables => "Plate,Array", -fields => \@fields, -values => \@values, -autoquote => 1 );
    my $ok_microarray = $dbc->Table_update_array( "Microarray", ['Microarray_Status'], ['Used'], "WHERE Microarray_ID = '$microarray_id'", -autoquote => 1 );
    my @new_plates = @{ $dbc->newids('Plate') };
    $self->primary_value( -table => 'Plate', -value => $new_plates[0] );
    $self->{plate_id} = $new_plates[0];
    Message("New plate(s) created with $chip_name");
    return $new_plates[0];
}

return 1;

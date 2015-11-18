################################################################################
# Clone_Sample.pm
#
# This module handles Clone_Sample based functions
#
###############################################################################
package alDente::Clone_Sample;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Clone_Sample.pm - This module handles Clone_Sample based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Clone_Sample based functions<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(alDente::Sample);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);

##############################
# custom_modules_ref         #
##############################
use alDente::Sample;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::Conversion;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;

##############################
# global_vars                #
##############################
use vars qw($project_dir $Connection);
use vars qw($testing);

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

    my $dbc        = $args{-dbc} || $Connection || $args{-connection};    # Database handle
    my $id         = $args{-id};
    my $ids        = $args{-ids};
    my $plate_id   = $args{-plate_id} || 0;
    my $attributes = $args{-attributes};                                  ## allow inclusion of attributes for new record
    my $encoded    = $args{-encoded} || 0;                                ## reference to encoded object (frozen)

    my ($class) = ref($this) || $this;

    my $self = alDente::Sample->new( -dbc => $dbc, -encoded => $encoded );
    $self->add_tables('Clone_Sample');

    $self->{dbc} = $dbc;

    bless $self, $class;

    return $self;

}

##############################
# Create a set of Clone_Samples for a plate
# return: 1 if successful, 0 if not
##############################
sub create_clone_samples {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );

    Message("Code should not come here...redivert through alDente::Sample::create_samples");
    Call_Stack();

    my $dbc       = $self->{dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);    # (ObjectRef) The connection object of the transaction
    my $plate_id  = $args{-plate_id};               # (Scalar) ID of the plate to add Clone_Samples to
    my $source_id = $args{-source_id};              # (Scalar) Source ID of the source that this plate is being created from

    unless ($source_id) {
        $source_id = '';
    }

    # retrieve properties of the plate
    my ( $plate_number, $lib, $plate_size ) = @{ $dbc->Table_retrieve( "Plate", [ "Plate_Number", "FK_Library__Name", "Plate_Size" ], "WHERE Plate_ID = $plate_id", -format => "RA" ) };

    # for Clone_Samples:  create Clone_Sample, Plate_Sample, and Sample records as necessary
    my $condition;
    my $well_field;

    if ( $plate_size =~ /96/ ) {
        $well_field = 'Plate_96';
        $condition  = "WHERE Quadrant='a'";
    }
    elsif ( $plate_size =~ /384/ ) {
        $well_field = 'Plate_384';
        $condition  = '';
    }
    else {
        $well_field = "N/A";
        $condition  = '';
    }

    # build a hash with all the wells to insert as the key and the quadrant as the value
    my %Map;
    my @wells;

    # retrieve the source plate id if this is created from a source that exists in the system
    my $plate_source = '';
    if ($source_id) {
        ($plate_source) = $dbc->Table_find( 'Source', 'FKSource_Plate__ID', "WHERE Source_ID=$source_id" );
    }
    my @parent_samples;

    ## if there is a source plate id, determine the sources that need to be linked to each individual sample
    # optimization - if the source plate is a tube, just grab the sample ID ONCE
    my $plate_source_type = undef;
    my $tube_sample       = undef;
    if ($plate_source) {
        ($plate_source_type) = $dbc->Table_find( "Plate", "Plate_Type", "WHERE Plate_ID=$plate_source" );
        if ( $plate_source_type eq 'Tube' ) {
            my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_source );
            $tube_sample = $Ancestry{sample_id};
        }
    }

    # if necessary, retrieve source sample by searching through the inheritance tree of the source
    if ( $well_field ne 'N/A' ) {
        my @well_info = $dbc->Table_find( 'Well_Lookup', "$well_field,Quadrant", "$condition" );
        foreach my $row (@well_info) {
            my ( $well, $quad ) = split ',', $row;
            $well = &format_well($well);
            push( @wells, $well );
            $Map{$well} = $quad;
            if ( $plate_source && ( $plate_source_type eq 'Tube' ) ) {
                push( @parent_samples, $tube_sample );
            }
            elsif ($plate_source) {
                my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_source, -well => $well );
                my $sample_id = $Ancestry{sample_id};
                push( @parent_samples, $sample_id );
            }
        }
    }
    else {
        push( @wells, $well_field );
        $Map{$well_field} = '';
    }

    # build insert hash for smart_append
    # inserting into tables Sample,Clone_Sample, and Plate_Sample
    my %clone_sample_info;
    foreach my $i ( 0 .. $#wells ) {
        my $well = $wells[$i];
        my $quad = '';
        if ( $plate_size =~ /384/ ) {
            $quad = $Map{$well};
        }

        # custom code - do not add in a well if there is only one well
        my $sample_name = "$lib-${plate_number}\_$well";
        if ( $well eq 'N/A' ) {
            $sample_name = "$lib-${plate_number}";
        }

        $clone_sample_info{ $i + 1 } = [ $sample_name, 'Clone', $source_id, $parent_samples[$i], $plate_id, $well, $well, $quad, $plate_number, $lib ];
    }

    my $ok = $dbc->smart_append(
        -tables => 'Sample,Clone_Sample,Plate_Sample',
        -fields =>
            [ 'Sample.Sample_Name', 'Sample.Sample_Type', 'Sample.FK_Source__ID', 'Sample.FKParent_Sample__ID', 'FKOriginal_Plate__ID', 'Clone_Sample.Original_Well', 'Plate_Sample.Well', 'Original_Quadrant', 'Library_Plate_Number', 'FK_Library__Name' ],
        -values    => \%clone_sample_info,
        -autoquote => 1
    );

    if ($ok) {
        return 1;
    }
    else {
        return 0;
    }

}

##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Clone_Sample.pm,v 1.5 2004/09/14 18:49:16 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
